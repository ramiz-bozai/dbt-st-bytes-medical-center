-- Lakehouse Federation demo setup (run in SQL editor or as a workflow task)
-- Replace connection/credential placeholders with your workspace values.
-- Docs: https://docs.databricks.com/en/query-federation/

-- 1) Create a connection to an external operational store (example: PostgreSQL)
-- CREATE CONNECTION IF NOT EXISTS fifa_ops_postgres
--   TYPE postgresql
--   OPTIONS (
--     host 'your-postgres-host',
--     port '5432',
--     user 'readonly',
--     password secret('fifa-postgres-password')
--   );

-- 2) Create a foreign catalog mapped to that connection
-- CREATE FOREIGN CATALOG IF NOT EXISTS federation_fifa
--   CONNECTION fifa_ops_postgres
--   OPTIONS (database 'fifa_ops');

-- 3) Grant access to analysts / dbt service principal
-- GRANT USE CATALOG ON CATALOG federation_fifa TO `your-dbt-sp`;
-- GRANT SELECT ON SCHEMA federation_fifa.public TO `your-dbt-sp`;

-- 4) Foreign table expected by dbt (see models/staging/federation_sources.yml)
-- In the foreign DB you would have: public.fifa_rankings(team_id, ranking_points, ranking_as_of)
-- SELECT * FROM federation_fifa.public.fifa_rankings LIMIT 10;

-- ---------------------------------------------------------------------------
-- Local / lab shortcut (no foreign DB): seed the same shape into UC
-- ---------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS ${catalog}.federation
  COMMENT 'Simulates federated rankings when foreign catalog is not configured';

-- After `dbt seed`, rankings live at ${catalog}.federation.raw_fifa_rankings
-- dbt vars (defaults): federated_catalog = target catalog, federated_schema = federation
