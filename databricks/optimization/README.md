# Table optimization

| File | Purpose |
|------|---------|
| `01_automatic_liquid_clustering.sql` | `CLUSTER BY` / `CLUSTER BY AUTO` inspection and reinforcement on gold facts |
| `02_refresh_materialized_view.sql` | `REFRESH MATERIALIZED VIEW` for the `mv_*` models |

**dbt already handles clustering at build time:** `dbt_project.yml` sets
`+auto_liquid_cluster: true` on the staging, intermediate, and marts layers, so models opt into
automatic liquid clustering as they are created. The SQL here is for verifying or overriding that
after a run — it is not required for a normal `dbt build`.

The materialized views (`mv_revenue_cycle_kpis`, `mv_encounter_volume_by_class`) are dbt models;
use `02_*` when you want to refresh them without a rebuild.
