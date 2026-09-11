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

The repository bundles the files under `seeds/st_bytes_medical_center/`. Upload them with:

```bash
./scripts/upload_mock_data.sh "$SYNTHEA_VOLUME_PATH"
```

Because staging models are streaming tables, a model that previously existed as a plain table
needs one `dbt run --select <model> --full-refresh` to be recreated.

## Note on `dbt seed`

The CSVs are checked in under `seeds/` so a fresh clone is self-contained. `dbt seed` is not part
of the normal flow: the upload helper copies the files to the volume and staging reads them with
`read_files()`. Seed resources are disabled in `dbt_project.yml` so `dbt build` does not load an
unused second copy; nothing in `models/` reads seeded tables.

## Alternative: SDP owns bronze

If you want a pipeline to land bronze tables instead of reading files from dbt, the pattern is
**Spark Declarative Pipelines** writing `{catalog}.raw.raw_*`.

> No SDP pipeline file currently lives in this repo — `databricks/sdp/` holds notes only. Adopting
> this route means adding the pipeline **and** reworking staging models to select from those
> tables (a `source()` layer), since today they read the volume directly.
