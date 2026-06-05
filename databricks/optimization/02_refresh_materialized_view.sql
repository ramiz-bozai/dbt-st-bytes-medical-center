-- Refresh dbt materialized views (dashboard acceleration layer)
-- Run after: dbt run --select mv_encounter_volume_by_class mv_revenue_cycle_kpis
-- Requires: DBR / warehouse that supports Unity Catalog materialized views

USE CATALOG ${catalog};
USE SCHEMA ${gold_schema};

REFRESH MATERIALIZED VIEW mv_encounter_volume_by_class;
REFRESH MATERIALIZED VIEW mv_revenue_cycle_kpis;

-- SELECT * FROM mv_encounter_volume_by_class ORDER BY encounter_volume_rank;
-- SELECT * FROM mv_revenue_cycle_kpis ORDER BY amount_rank;
