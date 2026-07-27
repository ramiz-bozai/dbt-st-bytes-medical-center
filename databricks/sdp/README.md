# SDP — bronze ingest (not currently used)

**No pipeline file lives here.** This directory holds notes only.

Bronze today is handled inside dbt: `stg_*` models are streaming tables that read the Synthea CSVs
from a Unity Catalog volume with `read_files()` (see `macros/stream_read_synthea_csv.sql` and
`vars.synthea_volume_path`). There is no `raw_*` table layer and no dbt `source()`.

If you want a Spark Declarative Pipeline to own bronze instead, it would write
`{catalog}.raw.raw_*` and staging models would need to be reworked to select from those tables.
Background: [../../docs/bronze_ingestion.md](../../docs/bronze_ingestion.md).
