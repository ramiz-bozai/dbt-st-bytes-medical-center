# Bronze — St. Bytes Medical Center

## In practice: SDP (recommended)

Use **Spark Declarative Pipelines** to load Synthea exports from cloud storage:

- Pipeline: `databricks/sdp/st_bytes_bronze_pipeline.py`
- Target: `{catalog}.raw.raw_*` (18 tables)
- Audit columns: `_ingested_at`, `_source_system`, `_row_hash`

dbt only **reads** bronze via `source('bronze', 'raw_<table>')` in staging models.

## In the lab: dbt seed (shortcut)

For local runs without a pipeline:

```bash
dbt seed --full-refresh
```

| Seed file | Bronze table (`raw` schema) |
|-----------|----------------------------|
| `patients.csv` | `raw_patients` |
| `encounters.csv` | `raw_encounters` |
| `claims_transactions.csv` | `raw_claims_transactions` |
| … | 18 tables total — see `dbt_project.yml` `seeds:` |

**Do not** `dbt seed` after SDP has loaded the same tables in production.

## Switching SDP schema

If SDP writes to `bronze` instead of `raw`:

```bash
dbt run --vars '{"bronze_schema": "bronze"}'
```

Silver and gold models are unchanged.
