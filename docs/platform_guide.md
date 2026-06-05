# St. Bytes Medical Center — Databricks platform guide

Lakehouse demo using **Synthea** synthetic healthcare data for a Massachusetts provider network. This guide maps **six Databricks capabilities** to repo artifacts and a repeatable demo flow.

| # | Concept | Primary repo artifacts |
|---|---------|----------------------|
| 1 | Spark Declarative Pipelines (SDP) + dbt | `databricks/sdp/st_bytes_bronze_pipeline.py`, `models/staging/__sources.yml` |
| 2 | Lakehouse Federation | `databricks/federation/` (optional pattern) |
| 3 | Unity Catalog metrics views | `databricks/metrics/02_encounter_volume_metrics_view.sql` |
| 4 | Automatic liquid clustering | `dbt_project.yml`, `databricks/optimization/01_*.sql` |
| 5 | Materialized views | `databricks/optimization/02_refresh_materialized_view.sql` (pattern) |
| 6 | Query tags & comments | `dbt_project.yml`, `macros/query_comment_json.sql` |

**Data profile:** [data_profile_st_bytes.md](data_profile_st_bytes.md)  
**Bronze detail:** [bronze_ingestion.md](bronze_ingestion.md)

---

## Bronze in practice vs. this repo

| Mode | When | How bronze lands | dbt reads |
|------|------|------------------|-----------|
| **Production / practice** | Databricks workspace | **SDP** (Lakeflow Declarative Pipelines) ingests CSV/JSON from cloud storage or messaging | `source('bronze', 'raw_*')` — same table names |
| **Local / lab** | Laptop CI, quick iteration | **`dbt seed`** loads `seeds/st_bytes_medical_center/*.csv` into schema `raw` | Identical `sources.bronze` definitions |

Silver and gold **always** run in dbt. Only the bronze loader changes.

```text
  [Synthea export / EHR feed]
           │
           ├─ PRACTICE ──► SDP pipeline ──► catalog.raw.raw_*
           │
           └─ LAB ───────► dbt seed ─────► catalog.raw.raw_*
                                       │
                                       ▼
                              dbt silver (stg_*, int_*)
                                       │
                                       ▼
                              dbt gold (dim_*, fct_*, mart_*)
```

Point SDP output at the same **`raw_*` table names** listed in `models/staging/__sources.yml` so you can switch from seed to pipeline without changing staging SQL.

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

## Local shortcut (no SDP)

When you only have the repo and a SQL warehouse:

```bash
dbt seed --full-refresh   # bronze into raw.*
dbt run
dbt test
```

Use the same `dbt run` / test commands after SDP in production — only the bronze step differs.

---

## 1. SDP + dbt (batch & streaming)

### Practice: SDP owns bronze

- Pipeline: `databricks/sdp/st_bytes_bronze_pipeline.py`  
- Upload `seeds/st_bytes_medical_center/*.csv` to cloud storage (or mount the repo path in a workspace).  
- Configure `CATALOG`, `BRONZE_SCHEMA`, and `BATCH_PATH` at the top of the notebook.  
- Run as a **Lakeflow Pipeline**; target schema should match `vars.bronze_schema` (default `raw`).

Each `@dlt.table` writes a `raw_*` name that matches `__sources.yml`. Audit columns mirror the seeded files: `_ingested_at`, `_source_system`, `_row_hash` (hash can be added in SDP with `sha2` of row contents).

### Optional streaming extension

High-volume tables are good streaming candidates:

- **`raw_claims_transactions`** — continuous charge/payment feeds  
- **`raw_observations`** — device/streaming vitals  

Pattern: Auto Loader bronze stream → `unionByName` with batch table (same approach as the legacy NBA box-score stream in `nba_bronze_pipeline.py`).

### dbt contract

```yaml
# models/staging/__sources.yml
sources:
  - name: bronze
    schema: "{{ var('bronze_schema') }}"   # raw
    tables:
      - name: raw_encounters
      # ...
```

Override schema when SDP writes to `bronze` instead of `raw`:

```bash
dbt run --vars '{"bronze_schema": "bronze"}'
```

**Do not** run `dbt seed` on top of SDP-managed tables in production (double load). Pick one bronze path per environment.

---

## 2. Lakehouse Federation (optional)

Not required for the core Synthea demo. Use when reference data lives **outside** your primary catalog:

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

Configured in `dbt_project.yml` for large facts:

| Model | Cluster keys |
|-------|----------------|
| `fct_encounters` | `encounter_start_date`, `patient_id` |
| `fct_claim_transactions` | `service_date`, `patient_id` |
| `fct_observations` | `observation_date`, `patient_id` |

Post-run, reinforce or inspect:

```bash
# databricks/optimization/01_automatic_liquid_clustering.sql
```

`dbt run` applies `CLUSTER BY` hints; optimization SQL validates clustering in the workspace.

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

| Variable | Purpose |
|----------|---------|
| `DATABRICKS_HOST` | Workspace URL |
| `DATABRICKS_HTTP_PATH` | SQL warehouse HTTP path |
| `DATABRICKS_CATALOG` | Unity Catalog name |
| `DATABRICKS_SCHEMA` | dbt target schema (silver/gold) |
| `DATABRICKS_TOKEN` | PAT |

Profile: `st_bytes_medical_center` in `profiles.yml.example`.

---

## File index

```text
seeds/st_bytes_medical_center/*.csv          # lab bronze only
models/staging/__sources.yml                 # bronze contract
models/staging/stg_*.sql                     # silver staging
models/intermediate/int_*.sql                # silver intermediate
models/marts/{dim,fct,mart}_*.sql            # gold
docs/{platform_guide,data_profile_st_bytes,bronze_ingestion}.md
databricks/sdp/st_bytes_bronze_pipeline.py   # practice bronze
databricks/{metrics,optimization,federation,demo}/
macros/{cast_helpers,query_comment_json,generate_schema_name}.sql
```

---

## Checklist before a customer demo

- [ ] Bronze loaded via **SDP** (or `dbt seed` for dry run)  
- [ ] `raw_*` row counts match expectations (~111 patients, ~5.7K encounters)  
- [ ] `dbt run` + `dbt test` green  
- [ ] Query History shows `layer=gold` tags on mart builds  
- [ ] Metrics view created and queryable  
- [ ] Talking point: seeds are stand-in; **SDP is the production bronze path**
