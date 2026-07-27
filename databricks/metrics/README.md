# UC Metrics Views

| File | Purpose |
|------|---------|
| `02_encounter_volume_metrics_view.sql` | Metrics view over the encounter marts |

Create after gold tables exist.

**dbt also builds metric views directly.** `models/metrics/` uses `+materialized: metric_view`
(see `dbt_project.yml`) for `metric_rc_transactions`, `metric_rc_claims`, and
`metric_rc_encounter_costs`, so those are managed by `dbt build` — no manual SQL needed. The file
here is for metrics views you want to deploy outside the dbt graph.
