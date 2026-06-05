-- UC Metrics View on dbt mart player_box_scores
-- Replace ${catalog} and ${gold_schema}

USE CATALOG ${catalog};
USE SCHEMA ${gold_schema};

CREATE OR REPLACE METRICS VIEW team_scoring_metrics (
  total_points COMMENT 'Sum of player points in box scores'
    MEASURE SUM(pts),
  games_logged COMMENT 'Box score rows'
    MEASURE COUNT(box_score_id),
  avg_points_per_game COMMENT 'Average points per box score row'
    MEASURE AVG(CAST(pts AS DOUBLE))
)
COMMENT 'NBA scoring metrics by team and season (Basketball-Reference lineage)'
DIMENSION team_abbrev COMMENT 'Team abbreviation'
DIMENSION season_end_year COMMENT 'Season end year'
AS
SELECT
    box_score_id,
    pts,
    team_abbrev,
    season_end_year
FROM ${catalog}.${gold_schema}.player_box_scores;
