# Table optimization

| File | Purpose |
|------|---------|
| `01_automatic_liquid_clustering.sql` | `CLUSTER BY` + `CLUSTER BY AUTO` on gold facts |
| `02_refresh_materialized_view.sql` | Refresh `team_goal_totals_mv` |

**dbt:** `goals` and `matches` also set `liquid_clustered_by` in `dbt_project.yml` at build time.
