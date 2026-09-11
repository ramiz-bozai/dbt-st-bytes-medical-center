# St. Bytes Medical Center — dbt analytics

dbt project for **Synthea** synthetic healthcare data at St. Bytes Medical Center (Massachusetts).

## Medallion layout

| Layer | Location | Objects |
|-------|----------|---------|
| **Bronze** | Synthea CSVs in a Unity Catalog volume | 18 source files |
| **Silver** | `models/staging/`, `models/intermediate/` | `stg_*` streaming tables, `int_*` tables |
| **Gold** | `models/marts/` | `dim_*`, `fct_*`, `mart_*` tables |

See [docs/data_profile_st_bytes.md](docs/data_profile_st_bytes.md) for the data survey and [docs/platform_guide.md](docs/platform_guide.md) for the Databricks demo flow.

---

## Customer setup

This repository includes all 18 Synthea CSV files needed to run the project. The files are
synthetically generated and contain no real patient data. Some columns intentionally look like
PII (including names, addresses, SSNs, driver license numbers, and passport numbers) so
healthcare governance patterns can be demonstrated. **Do not mix this dataset with real PHI or
use it for production workloads.**

### Prerequisites

- Python 3.10 or newer
- A Databricks workspace with Unity Catalog
- A Databricks SQL warehouse
- The [Databricks CLI](https://docs.databricks.com/dev-tools/cli/install.html) (only if you use the upload helper below)
- Permission to create or use a catalog, schema, and managed volume

### 1. Create the Unity Catalog locations

Run the following in the Databricks SQL editor, replacing the example names:

```sql
CREATE CATALOG IF NOT EXISTS your_catalog;
CREATE SCHEMA IF NOT EXISTS your_catalog.raw_uploads;
CREATE VOLUME IF NOT EXISTS your_catalog.raw_uploads.synthea_csvs;

CREATE CATALOG IF NOT EXISTS your_dev_catalog;
CREATE SCHEMA IF NOT EXISTS your_dev_catalog.dbt_your_name;

-- Optional production target
CREATE CATALOG IF NOT EXISTS your_prod_catalog;
CREATE SCHEMA IF NOT EXISTS your_prod_catalog.default;
```

The principal running dbt needs `USE CATALOG`, `USE SCHEMA`, and permission to create tables in
the target catalog/schema. It also needs `READ VOLUME` on the source volume and `CAN USE` on the
SQL warehouse. The identity running the upload helper also needs `WRITE VOLUME`.

### 2. Configure the project

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.template .env
```

Edit `.env` with the customer's workspace host, SQL warehouse HTTP path, target catalogs and
schemas, token, and volume path. Keep `.env` local; it is gitignored.

### 3. Upload the bundled mock data

The 18 CSVs live in `seeds/st_bytes_medical_center/`. Put them in the Unity Catalog volume you
created in step 1 — either with the helper script or by uploading the files yourself.

**Option A — helper script** (needs the Databricks CLI and `WRITE VOLUME`):

```bash
set -a && source .env && set +a
./scripts/upload_mock_data.sh "$SYNTHEA_VOLUME_PATH"
```

The script verifies that all 18 expected CSVs are present before uploading them.

**Option B — Catalog Explorer (or any other volume upload):** download or copy the CSVs from
`seeds/st_bytes_medical_center/` and upload them into the volume in the Databricks UI
(Catalog → schema → volume → Upload). File names must match the originals (`patients.csv`,
`encounters.csv`, …). No CLI required.

The checked-in dataset contains 111 patients, 5,745 encounters, 9,995 claims, and 95,313 claim
transactions (excluding each file's header row). Point `SYNTHEA_VOLUME_PATH` in `.env` at that
volume either way.

### 4. Build and test

```bash
dbt deps
dbt debug
dbt build
dbt test --select marts
```

If staging tables already exist as non-streaming tables, recreate them once with
`dbt run --select staging --full-refresh`.

---

## Running dbt here

### One-time setup

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.template .env        # fill in the customer workspace values
dbt deps
```

### Every session

```bash
source .venv/bin/activate
set -a && source .env && set +a
```

`dbt` is only installed inside `.venv`, so it is not on your global `PATH`. Either activate the
venv or call `.venv/bin/dbt` directly.

The `set -a` wrapper matters: `.env` is plain `KEY=value` lines with no `export`, so without it
the values never reach dbt's environment.

### Then run normally

```bash
dbt build                        # everything: staging reads the volume directly, no seed step
dbt run  --select staging+       # or just one slice of the graph
dbt test --select marts          # tests on their own
```

You do **not** need `--profiles-dir`. dbt resolves `profiles.yml` from the current working
directory before falling back to `~/.dbt/`, and this repo keeps `profiles.yml` at its root — so
plain `dbt run` from the repo root just works.

---

## Configuration: why profiles.yml is committed

`profiles.yml` is deliberately **not** gitignored, but it holds no environment-specific values
or secrets. Host, `http_path`, catalog, schema, and token are all `env_var()` references resolved
at runtime:

| | Local laptop | Databricks job |
|---|---|---|
| **Where the profile comes from** | `profiles.yml` at the repo root | the same committed file, synced with the repo |
| **How values are set** | `set -a && source .env && set +a` | configure the non-secret connection variables in the job environment; Databricks injects `DBT_ACCESS_TOKEN` for the *Run As* principal |
| **Profiles Directory setting** | n/a (found via cwd) | leave **blank** — it defaults to the repo root |

Committing the file keeps the Databricks side simple: a dbt task syncs this repo and finds
`profiles.yml` where it already lives. Nothing containing customer values or secrets lands in
git.

`.env` is gitignored and is the **local-only** counterpart. Use `.env.template` (tracked) as the
checklist of what to fill in.

### Configuring the Databricks dbt task

Because we bring our own `profiles.yml`, the task must be set up the "custom profile" way — see
`databricks/demo/lakeflow_job_outline.json` for a worked example:

- **SQL warehouse: `None (Manual)`.** The warehouse comes from `http_path` in `profiles.yml`. If
  you pick a warehouse in the UI instead, Databricks generates its own profile and ignores ours.
- **Profiles Directory: blank** — defaults to the repository root.
- Make `DATABRICKS_HOST`, `DATABRICKS_HTTP_PATH`, `DATABRICKS_CATALOG_DEV`,
  `DATABRICKS_SCHEMA_DEV`, `DATABRICKS_CATALOG_PROD`, `DATABRICKS_SCHEMA_PROD`, and
  `SYNTHEA_VOLUME_PATH` available to the task
  environment. The job's *Run As* principal supplies the short-lived `DBT_ACCESS_TOKEN`.
- **Leave catalog and schema unset** on the task. They can only be set when a warehouse is
  selected, so leaving them populated fails validation with
  `Catalog can only be defined if the warehouseId is defined.` Our catalog/schema come from the
  target in `profiles.yml`.
- The project must live in a **Databricks Git folder** — dbt tasks cannot run from DBFS.
- The *Run As* principal needs `CAN USE` on the warehouse plus the usual Unity Catalog grants
  (`USE CATALOG` / `USE SCHEMA`, and `SELECT` or `MODIFY`) on what the models read and write.

The injected token is valid for the run's duration and is revoked automatically afterward.

### Targets

| Target | Catalog | Schema | Notes |
|--------|---------|--------|-------|
| `dev` *(default)* | `DATABRICKS_CATALOG_DEV` | `DATABRICKS_SCHEMA_DEV` | personal development schema |
| `prod` | `DATABRICKS_CATALOG_PROD` | `DATABRICKS_SCHEMA_PROD` | `dbt run --target prod` |

---

## Where bronze comes from

Staging models read the Synthea CSVs **straight out of a Unity Catalog volume** — there is no
bronze `raw_*` table layer and no `source()` in this project. Each `stg_*` model is a streaming
table fed by `read_files()` through the `stream_read_synthea_csv` macro:

```sql
{{ stream_read_synthea_csv('allergies.csv') }}
```

The volume path is a single dbt var in `dbt_project.yml`, so pointing at a different upload
location is a one-line change (or a `--vars` override):

```yaml
vars:
  synthea_volume_path: "{{ env_var('SYNTHEA_VOLUME_PATH') }}"
```

Two consequences worth knowing:

- **`seeds/` contains the bundled CSVs**, but `dbt seed` is not part of the normal flow. Upload
  them with `scripts/upload_mock_data.sh` or by dropping the files into a UC volume in Catalog
  Explorer; staging reads the volume directly. Seed resources are disabled in `dbt_project.yml`
  so plain `dbt build` does not load an unused second copy.
- **Staging models are streaming tables.** If a model was previously materialized as a plain
  table, Databricks cannot convert it in place — run
  `dbt run --select <model> --full-refresh` once to recreate it.

---

## Gold analytics (examples)

- **Patient 360:** `mart_patient_summary`, `mart_vital_signs_latest`
- **Operations:** `mart_encounter_class_distribution`, `mart_provider_panel`, `mart_organization_utilization`
- **Revenue cycle:** `mart_revenue_cycle`, `mart_claims_aging`, `fct_claim_transactions`
- **Clinical:** `mart_chronic_conditions`, `mart_medication_utilization`, `mart_immunization_coverage`
- **Population:** `mart_population_health`

## Model documentation

Model and column descriptions live in `models/**/_*.yml` and are edited by hand.

`dbt_project.yml` sets `+persist_docs: {relation: true, columns: true}`, so these descriptions are
pushed into Unity Catalog as table and column `COMMENT`s on every run — they are catalog metadata,
not just dbt-docs text. Keep shared columns (`patient_id`, `encounter_id`, `ingested_at`, …)
worded consistently across files, since they describe the same thing everywhere.

## Data source

Synthetic data generated with [Synthea](https://github.com/synthetichealth/synthea). Not for production PHI.
