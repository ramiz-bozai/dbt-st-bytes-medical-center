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

## Running dbt here

### One-time setup

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.template .env        # fill in DBT_ACCESS_TOKEN (a PAT) at minimum
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
the values never reach dbt's environment and every command fails with
`Parsing Error: Env var required but not provided: 'DBT_ACCESS_TOKEN'`.

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

`profiles.yml` is deliberately **not** gitignored, and it holds no secrets. Host, `http_path`,
catalog, and schema are plain non-sensitive values; the only credential — the token — is a
`{{ env_var('DBT_ACCESS_TOKEN') }}` reference resolved at runtime:

| | Local laptop | Databricks job |
|---|---|---|
| **Where the profile comes from** | `profiles.yml` at the repo root | the same committed file, synced with the repo |
| **How `DBT_ACCESS_TOKEN` is set** | you `source .env` | Databricks **injects it automatically** for the job's *Run As* principal |
| **Profiles Directory setting** | n/a (found via cwd) | leave **blank** — it defaults to the repo root |

Committing the file is what makes the Databricks side trivial: a dbt task syncs this repo, finds
`profiles.yml` where it already lives, and gets a short-lived token injected into the task
runtime. Nothing to copy into the workspace, and no secret ever lands in git.

`.env` is gitignored and is the **local-only** counterpart — it exists so your laptop can supply
the same `DBT_ACCESS_TOKEN` that Databricks supplies for itself. Use `.env.template` (tracked) as
the checklist of what to fill in.

### Configuring the Databricks dbt task

Because we bring our own `profiles.yml`, the task must be set up the "custom profile" way — see
`databricks/demo/lakeflow_job_outline.json` for a worked example:

- **SQL warehouse: `None (Manual)`.** The warehouse comes from `http_path` in `profiles.yml`. If
  you pick a warehouse in the UI instead, Databricks generates its own profile and ignores ours.
- **Profiles Directory: blank** — defaults to the repository root.
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
| `dev` *(default)* | `st_bytes_medical_center_dev` | `dbt_rbozai` | personal dev schema |
| `prod` | `st_bytes_medical_center_prod` | `default` | `dbt run --target prod` |

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
  synthea_volume_path: "/Volumes/ramiz_fevm_gcp_central1/raw_uploads/synthea_csvs"
```

Two consequences worth knowing:

- **`seeds/` is gitignored**, so a fresh clone has no CSVs and `dbt seed` is not part of the
  normal flow. The volume is the real source. The `seeds:` block in `dbt_project.yml` is a
  leftover fallback for loading local CSVs into `raw_*` tables if you ever want them.
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
