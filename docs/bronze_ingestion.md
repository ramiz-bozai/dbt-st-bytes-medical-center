# Bronze — St. Bytes Medical Center

## How it works today: CSVs in a UC volume

Staging models read the Synthea CSVs **directly from a Unity Catalog volume**. There is no
intermediate bronze `raw_*` table layer, and no dbt `source()` in this project.

- Volume path: `vars.synthea_volume_path` in `dbt_project.yml`
- Mechanism: `read_files()` via the `stream_read_synthea_csv` macro
- Each `stg_*` model is a **streaming table** reading one CSV by `pathGlobFilter`
- Audit columns arrive in the files themselves: `_ingested_at`, `_source_system`, `_row_hash`

```sql
-- models/staging/stg_conditions.sql
select ...
{{ stream_read_synthea_csv('conditions.csv') }}
```

So bronze is just "the 18 CSVs uploaded to the volume." To repoint at a different upload
location, change the one var:

```bash
dbt run --vars '{"synthea_volume_path": "/Volumes/my_catalog/my_schema/synthea"}'
```

Because staging models are streaming tables, a model that previously existed as a plain table
needs one `dbt run --select <model> --full-refresh` to be recreated.

## Note on `dbt seed`

`seeds/` is **gitignored**, so a fresh clone has no CSVs and `dbt seed` is not part of the normal
flow. The `seeds:` block in `dbt_project.yml` still maps each CSV to a `raw_*` alias, so it works
as a local fallback if you have the files — but nothing in `models/` reads those tables.

## Alternative: SDP owns bronze

If you want a pipeline to land bronze tables instead of reading files from dbt, the pattern is
**Spark Declarative Pipelines** writing `{catalog}.raw.raw_*`.

> No SDP pipeline file currently lives in this repo — `databricks/sdp/` holds notes only. Adopting
> this route means adding the pipeline **and** reworking staging models to select from those
> tables (a `source()` layer), since today they read the volume directly.
