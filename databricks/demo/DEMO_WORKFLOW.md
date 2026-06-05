# St. Bytes Medical Center — demo workflow

## Assets in Databricks

| Asset | Source |
|-------|--------|
| Lakeflow Pipeline `st_bytes_bronze` | `databricks/sdp/st_bytes_bronze_pipeline.py` |
| Repo `dbt-fifa-analytics` | Workspace Repos |
| Job outline | `databricks/demo/lakeflow_job_outline.json` |

## Bronze: practice vs lab

| Path | Command / action |
|------|------------------|
| **Practice** | Upload `seeds/st_bytes_medical_center/*.csv` to cloud storage → run SDP pipeline |
| **Lab** | `dbt seed --full-refresh` (skip SDP) |

Do not run both on the same `raw.*` tables in one environment.

## 60-minute flow

| Min | Step |
|-----|------|
| 0–10 | Upload CSVs; configure `BATCH_PATH` in SDP notebook |
| 10–20 | Run `st_bytes_bronze` pipeline (18 `raw_*` tables) |
| 20–40 | `dbt run` — walk `stg_encounters` → `int_encounters_enriched` → `mart_patient_summary` |
| 40–45 | Query History — filter `domain=healthcare`, `layer=gold` |
| 45–55 | Deploy `02_encounter_volume_metrics_view.sql`; optional MV refresh |
| 55–60 | Story: encounter mix + revenue cycle (`mart_revenue_cycle`) |

## Talking points

- **SDP** owns bronze in production; **dbt seed** is a dev shortcut.  
- **Encounters** are the clinical hub; **claims** link via `appointmentid`.  
- **Liquid clustering** on large facts (`fct_encounters`, `fct_claim_transactions`).  
- **Metrics views** decouple BI from raw mart table names.
