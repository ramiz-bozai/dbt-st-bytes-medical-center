-- Lakehouse Federation setup template (run in SQL editor or as a workflow task)
-- Nothing in this dbt project uses federation today -- see README.md in this directory.
-- Replace connection/credential placeholders with your workspace values.
-- Docs: https://docs.databricks.com/en/query-federation/

-- 1) Create a connection to an external operational store (example: PostgreSQL)
-- CREATE CONNECTION IF NOT EXISTS ref_data_postgres
--   TYPE postgresql
--   OPTIONS (
--     host 'your-postgres-host',
--     port '5432',
--     user 'readonly',
--     password secret('ref-data-postgres-password')
--   );

-- 2) Create a foreign catalog mapped to that connection
-- CREATE FOREIGN CATALOG IF NOT EXISTS federation_ref_data
--   CONNECTION ref_data_postgres
--   OPTIONS (database 'ref_data');

-- 3) Grant access to analysts / dbt service principal
-- GRANT USE CATALOG ON CATALOG federation_ref_data TO `your-dbt-sp`;
-- GRANT SELECT ON SCHEMA federation_ref_data.public TO `your-dbt-sp`;

-- 4) Expose the foreign table to dbt as a source, then ref it from a staging model.
-- Candidate reference data for this project (none wired up today):
--   payer metadata, NPI / provider registry, ZIP -> social determinants
-- SELECT * FROM federation_ref_data.public.payer_reference LIMIT 10;
