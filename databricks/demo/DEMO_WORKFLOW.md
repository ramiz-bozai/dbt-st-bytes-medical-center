# St. Bytes Medical Center — demo workflow

## Assets in Databricks

| Asset | Source |
|-------|--------|
| Volume holding the Synthea CSVs | `vars.synthea_volume_path` in `dbt_project.yml` |
| Repo `dbt-st-bytes-medical-center` | Workspace Repos / Git folder |
| Job outline | `databricks/demo/lakeflow_job_outline.json` |

## Bronze

Staging models stream the CSVs straight out of the UC volume with `read_files()`, so the dbt task
*is* the ingest step — there is no separate bronze pipeline to run. Just make sure all 18 CSVs are
uploaded to the volume before the demo. A fresh clone contains the files under
`seeds/st_bytes_medical_center/`; use `scripts/upload_mock_data.sh` to upload them.

The dbt task authenticates using the committed `profiles.yml` at the repo root, with
`DBT_ACCESS_TOKEN` injected automatically for the job's *Run As* principal. Configure the
`DATABRICKS_*` and `SYNTHEA_VOLUME_PATH` values in the task environment. Leave the task's
**Profiles Directory** blank so it defaults to the repo root. See
[../../README.md](../../README.md).

## 60-minute flow

| Min | Step |
|-----|------|
| 0–10 | Confirm CSVs in the volume; show `vars.synthea_volume_path` and the `stream_read_synthea_csv` macro |
| 10–20 | `dbt build --select staging` — 18 streaming tables reading the volume |
| 20–40 | `dbt build` — walk `stg_encounters` → `int_encounters_enriched` → `mart_patient_summary` |
| 40–45 | Query History — filter `domain=healthcare`, `layer=gold` |
| 45–55 | Deploy `02_encounter_volume_metrics_view.sql`; optional MV refresh |
| 55–60 | Story: encounter mix + revenue cycle (`mart_revenue_cycle`) |

## Talking points

- **dbt owns ingest** here: `read_files()` on a UC volume, no bronze table layer to maintain.  
- **Staging is streaming tables** — incremental file processing for free; first build of a
  previously-plain table needs `--full-refresh`.  
- **Encounters** are the clinical hub; **claims** link via `appointmentid`.  
- **Liquid clustering** on large facts (`fct_encounters`, `fct_claim_transactions`).  
- **Metrics views** decouple BI from raw mart table names.
