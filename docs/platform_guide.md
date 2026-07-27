# St. Bytes Medical Center — Databricks platform guide

Lakehouse demo using **Synthea** synthetic healthcare data for a Massachusetts provider network. This guide maps **six Databricks capabilities** to repo artifacts and a repeatable demo flow.

| # | Concept | Primary repo artifacts |
|---|---------|----------------------|
| 1 | Volume ingest in dbt (`read_files`) | `macros/stream_read_synthea_csv.sql`, `models/staging/stg_*.sql` |
| 2 | Lakehouse Federation | `databricks/federation/` (optional pattern) |
| 3 | Unity Catalog metrics views | `databricks/metrics/02_encounter_volume_metrics_view.sql` |
| 4 | Automatic liquid clustering | `dbt_project.yml`, `databricks/optimization/01_*.sql` |
| 5 | Materialized views | `databricks/optimization/02_refresh_materialized_view.sql` (pattern) |
| 6 | Query tags & comments | `dbt_project.yml`, `macros/query_comment_json.sql` |

**Data profile:** [data_profile_st_bytes.md](data_profile_st_bytes.md)  
**Bronze detail:** [bronze_ingestion.md](bronze_ingestion.md)

---

## How bronze lands in this repo

Staging models read the Synthea CSVs **directly from a Unity Catalog volume** via `read_files()`.
There is no bronze `raw_*` table layer and no dbt `source()` — bronze is simply the 18 CSVs
uploaded to `vars.synthea_volume_path`.

```text
  [Synthea export / EHR feed]
           │
           └─► CSVs uploaded to /Volumes/<catalog>/<schema>/synthea_csvs
                                       │
                                       ▼
                      dbt silver — stg_* streaming tables (read_files)
                                       │
                                       ▼
                              dbt int_* (tables)
                                       │
                                       ▼
                              dbt gold (dim_*, fct_*, mart_*)
```

Details and the SDP alternative: [bronze_ingestion.md](bronze_ingestion.md).
Credentials and how dbt is invoked locally vs. in a job: [../README.md](../README.md).

---

## Medallion map (what lives where)

### Bronze — raw ingest (18 tables)

**Not modeled in dbt SQL.** Tables are append-only landing copies of source files plus audit columns (`_ingested_at`, `_source_system`, `_row_hash`).

| Domain | `raw_*` table | Source file |
|--------|---------------|-------------|
| Population | `raw_patients` | `patients.csv` |
| Network | `raw_providers`, `raw_organizations` | `providers.csv`, `organizations.csv` |
| Coverage | `raw_payers`, `raw_payer_transitions` | `payers.csv`, `payer_transitions.csv` |
| Utilization | `raw_encounters` | `encounters.csv` |
| Revenue | `raw_claims`, `raw_claims_transactions` | `claims.csv`, `claims_transactions.csv` |
| Clinical | `raw_conditions`, `raw_procedures`, `raw_observations`, `raw_medications`, `raw_immunizations`, `raw_allergies`, `raw_careplans`, `raw_devices`, `raw_supplies`, `raw_imaging_studies` | matching CSVs |

**Hub:** `raw_encounters` links patients, providers, organizations, and payers; most clinical tables hang off `encounter` + `patient`.

### Silver — clean & conformed (views)

| Sub-layer | Prefix | Count | Role |
|-----------|--------|-------|------|
| Staging | `stg_*` | 18 | Rename keys, cast types, light flags (`is_active`, etc.) |
| Intermediate | `int_*` | 9 | Joins, rollups, demographics, claim financials, vitals |

Examples: `int_encounters_enriched` (visit + provider + payer context), `int_claim_financials` (charges/payments per claim).

### Gold — analytics-ready (tables)

| Sub-layer | Prefix | Count | Role |
|-----------|--------|-------|------|
| Dimensions | `dim_*` | 4 | Patients, providers, organizations, payers |
| Facts | `fct_*` | 11 | Encounters, claims, transactions, clinical events at operational grain |
| Marts | `mart_*` | 17 | KPIs: population health, revenue cycle, utilization, registries |

**Demo “hero” marts:** `mart_patient_summary`, `mart_encounter_cost_analysis`, `mart_revenue_cycle`, `mart_population_health`.

---

## Demo story (60 minutes)

1. **Bronze (SDP):** Run `st_bytes_bronze` pipeline — batch load all Synthea CSVs from cloud storage into `raw.raw_*`. Mention optional **streaming** path for late-arriving claim lines (see SDP file).  
2. **Silver (dbt):** `dbt run --select staging+ intermediate+` — show typed `stg_encounters` and enriched `int_encounters_enriched`.  
3. **Gold (dbt):** `dbt run --select marts` — patient 360 (`mart_patient_summary`) and revenue cycle (`mart_revenue_cycle`).  
4. **Optimize:** Liquid clustering on `fct_encounters` / `fct_claim_transactions`; optional **materialized view** on encounter aggregates.  
5. **Serve:** UC **metrics view** for BI semantic layer.  
6. **Govern:** Query History filtered by `layer=gold` and `domain=healthcare` tags.

**Narrative beat:** “Follow a patient from **encounter** through **conditions** and **claims**; compare **ambulatory vs emergency** volume and **charge vs payment** mix for the network.”

---

## Running it

With the CSVs already in the volume, all you need is the repo and a SQL warehouse:

```bash
source .venv/bin/activate
set -a && source .env && set +a

dbt build
```

Setup, credentials, and how a Databricks job picks up the committed `profiles.yml`:
[../README.md](../README.md).

---

## 1. SDP + dbt (batch & streaming)

### Today: dbt owns the file read

Staging models stream the CSVs out of the UC volume with `read_files()`, so dbt itself is the
ingest step — no separate bronze pipeline runs in this repo. Audit columns (`_ingested_at`,
`_source_system`, `_row_hash`) come from the files.

### Alternative: SDP owns bronze

Land `{catalog}.raw.raw_*` from a **Lakeflow Declarative Pipeline**, then point staging at those
tables via `source()` instead of `read_files()`. `databricks/sdp/` currently holds notes only — no
pipeline file is committed, so this is a pattern to build, not a path to run today.

### Optional streaming extension

High-volume tables are good streaming candidates:

- **`raw_claims_transactions`** — continuous charge/payment feeds  
- **`raw_observations`** — device/streaming vitals  

Pattern: Auto Loader bronze stream → `unionByName` with the batch table.

### dbt contract

Today staging reads the volume directly, so the only contract is the **volume path plus the CSV
filenames**:

```yaml
# dbt_project.yml
vars:
  synthea_volume_path: "/Volumes/<catalog>/raw_uploads/synthea_csvs"
```

```bash
dbt run --vars '{"synthea_volume_path": "/Volumes/other/path"}'
```

Adopting an SDP-owned `raw_*` table layer would mean reworking staging models to select from those
tables instead of `read_files()`. See [bronze_ingestion.md](bronze_ingestion.md).

---

## 2. Lakehouse Federation (optional)

**Nothing in this project uses federation today** — `stg_allergies` was the last model reading a
foreign catalog and it now streams from the volume like the rest. Keep this in mind as a pattern
for when reference data genuinely lives **outside** your primary catalog:

| Example use | Federated source | Consumed in dbt |
|-------------|------------------|-----------------|
| CMS payer metadata | External Delta table | `stg_payers` enrichment |
| NPI / provider registry | JDBC federation | `dim_providers` |
| Zip → social determinants | Shared marketplace dataset | `mart_population_health` |

Lab setup notes: `databricks/federation/01_lakehouse_federation_setup.sql` and `databricks/federation/README.md`.

---

## 3. Unity Catalog metrics views

Semantic layer for BI tools (Power BI, Tableau, AI/BI) without exposing the full mart layer.

1. Run `dbt run --select mart_encounter_class_distribution mart_population_health` (or full marts).  
2. Execute `databricks/metrics/02_encounter_volume_metrics_view.sql` in SQL editor.  
3. Grant `SELECT` on the metrics view to analysts.

Metrics views sit **above** gold and stay stable while facts evolve.

---

## 4. Automatic liquid clustering

`dbt_project.yml` sets `+auto_liquid_cluster: true` on the staging, intermediate, and marts layers,
so models are created with `CLUSTER BY AUTO` — Databricks picks and evolves the keys.

To pin explicit keys on a large fact instead, useful candidates are:

| Model | Cluster keys |
|-------|----------------|
| `fct_encounters` | `encounter_start_date`, `patient_id` |
| `fct_claim_transactions` | `service_date`, `patient_id` |
| `fct_observations` | `observation_at`, `patient_id` |

Inspect or override after a run with `databricks/optimization/01_automatic_liquid_clustering.sql`
(`DESCRIBE DETAIL` to see what is in place, `ALTER TABLE ... CLUSTER BY` to pin keys).

---

## 5. Materialized views

Gold marts are **tables** today. For dashboard latency, promote a heavy mart to a UC **materialized view**, e.g.:

- `mart_encounter_class_distribution` — encounter volume by class  
- `mart_revenue_cycle` — financial KPIs by transaction type  

Workflow:

1. Create MV in SQL or port mart logic to `CREATE MATERIALIZED VIEW`.  
2. After each dbt run, `REFRESH MATERIALIZED VIEW` — see `databricks/optimization/02_refresh_materialized_view.sql`.  
3. Point BI dashboards at the MV, not the base mart table.

---

## 6. Query tags & comments

**Warehouse tags** (filter in Query History) are JSON strings on folder config:

| Folder | Tags |
|--------|------|
| `staging` / `intermediate` | `{"layer":"silver","domain":"healthcare"}` |
| `marts` | `{"layer":"gold","domain":"healthcare"}` |

**Query comments** (JSON appended to SQL) come from `macros/query_comment_json.sql` — includes `project`, `node`, `layer`.

dbt-databricks requires **string** JSON for model-level `query_tags`; avoid YAML dicts (see dbt docs).

---

## Sample Lakeflow job

```text
st_bytes_bronze (SDP)
    → dbt_seed [SKIP in prod if SDP loaded bronze]
    → dbt_run (staging → intermediate → marts)
    → dbt_test
    → optimization_sql (clustering check)
    → metrics_view_deploy
    → refresh_materialized_view [optional]
```

Outline JSON: `databricks/demo/lakeflow_job_outline.json`  
Step-by-step: `databricks/demo/DEMO_WORKFLOW.md`

---

## Environment variables

`profiles.yml` is committed at the repo root and hardcodes the non-secret connection details
(host, `http_path`, catalog, schema per target). The **only** variable dbt itself needs is the
token:

| Variable | Purpose |
|----------|---------|
| `DBT_ACCESS_TOKEN` | The one var `profiles.yml` reads. Locally from `.env`; on a Databricks dbt task, **injected automatically** for the *Run As* principal. |
| `DATABRICKS_HOST`, `DATABRICKS_HTTP_PATH`, `DATABRICKS_TOKEN` | Used by the Databricks CLI and other tooling, not by `profiles.yml`. See `.env.template`. |

Full explanation of the local vs. job split: [../README.md](../README.md).

---

## File index

```text
profiles.yml                                 # committed, no secrets — see README
.env / .env.template                         # local secrets (.env is gitignored)
dbt_project.yml                              # vars.synthea_volume_path = bronze location
macros/stream_read_synthea_csv.sql           # the read_files() bronze read
models/staging/stg_*.sql                     # silver staging (streaming tables)
models/intermediate/int_*.sql                # silver intermediate
models/marts/{dim,fct,mart}_*.sql            # gold
models/**/_*.yml                             # model + column docs -> persisted as UC comments
docs/{platform_guide,data_profile_st_bytes,bronze_ingestion}.md
databricks/{metrics,optimization,federation,sdp,demo}/
macros/{cast_helpers,query_comment_json,generate_schema_name}.sql
seeds/st_bytes_medical_center/*.csv          # gitignored; unused fallback
```

---

## Checklist before a customer demo

- [ ] All 18 Synthea CSVs present in the volume at `vars.synthea_volume_path`  
- [ ] `source .env` done — otherwise dbt fails on the missing `DBT_ACCESS_TOKEN`  
- [ ] Row counts match expectations (~111 patients, ~5.7K encounters)  
- [ ] `dbt build` green  
- [ ] Query History shows `layer=gold` tags on mart builds  
- [ ] Metrics view created and queryable  
- [ ] Talking point: staging streams straight from the volume — dbt is the ingest step
