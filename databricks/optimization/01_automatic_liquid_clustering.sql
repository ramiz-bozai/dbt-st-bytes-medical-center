-- Automatic Liquid Clustering on dbt-built gold tables
-- Run after: dbt run --select goals matches
-- Requires: DBR / warehouse that supports liquid clustering (see workspace release notes)

USE CATALOG ${catalog};
USE SCHEMA ${gold_schema};

-- Explicit columns (predictable for demos)
ALTER TABLE player_box_scores
  CLUSTER BY (season_end_year, game_id);

ALTER TABLE games
  CLUSTER BY (season_end_year, game_date);

ALTER TABLE player_box_scores
  CLUSTER BY AUTO;

-- Optional: trigger clustering maintenance
-- ANALYZE TABLE goals COMPUTE STATISTICS;
