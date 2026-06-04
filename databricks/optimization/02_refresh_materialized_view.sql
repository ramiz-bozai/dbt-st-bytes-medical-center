-- Refresh dbt materialized view (team_goal_totals_mv)
USE CATALOG ${catalog};
USE SCHEMA ${gold_schema};

-- After promoting a gold mart to a materialized view, refresh it here.
-- Example: CREATE MATERIALIZED VIEW encounter_volume_mv AS SELECT * FROM mart_encounter_class_distribution;

-- REFRESH MATERIALIZED VIEW encounter_volume_mv;
-- SELECT * FROM encounter_volume_mv ORDER BY encounter_count DESC;
