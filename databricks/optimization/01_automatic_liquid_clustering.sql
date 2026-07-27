-- Automatic Liquid Clustering on dbt-built gold tables
-- Run after: dbt run --select marts
-- Requires: DBR / warehouse that supports liquid clustering (see workspace release notes)
--
-- Note: dbt_project.yml already sets +auto_liquid_cluster: true on staging, intermediate,
-- and marts, so models are created with CLUSTER BY AUTO. Use this file to inspect that, or
-- to pin explicit keys on a specific fact.

USE CATALOG ${catalog};
USE SCHEMA ${gold_schema};

-- Inspect what clustering is actually in place
DESCRIBE DETAIL fct_encounters;
DESCRIBE DETAIL fct_claim_transactions;
DESCRIBE DETAIL fct_observations;

-- Explicit keys (predictable for demos) -- overrides CLUSTER BY AUTO on that table
ALTER TABLE fct_encounters
  CLUSTER BY (encounter_start_date, patient_id);

ALTER TABLE fct_claim_transactions
  CLUSTER BY (service_date, patient_id);

-- Hand a table back to automatic clustering
ALTER TABLE fct_observations
  CLUSTER BY AUTO;

-- Optional: trigger clustering maintenance
-- OPTIMIZE fct_encounters;
-- ANALYZE TABLE fct_encounters COMPUTE STATISTICS;
