-- ABAC column masks for dim_patients (first_name, last_name)
-- Set the `catalog` query parameter before running this script.
-- Governed tag: customer_pii = name
-- Run once in SQL editor or as a Lakeflow task. Requires Databricks Runtime 16.4+.
--
-- Prerequisite: governed tag `customer_pii` exists with allowed value `name`.
-- After `dbt run --select dim_patients`, post-hooks apply the tag to both columns.

USE CATALOG ${catalog};

CREATE SCHEMA IF NOT EXISTS governance
  COMMENT 'Mask UDFs and governance helpers for Unity Catalog ABAC';

CREATE OR REPLACE FUNCTION governance.redact_patient_name(val STRING)
RETURNS STRING
RETURN CASE
  WHEN is_account_group_member('phi_readers') THEN val
  ELSE 'REDACTED'
END;

DROP POLICY IF EXISTS mask_customer_pii_name ON CATALOG ${catalog};

CREATE POLICY mask_customer_pii_name
ON CATALOG ${catalog}
COLUMN MASK governance.redact_patient_name
TO `account users`
FOR TABLES
MATCH COLUMNS has_tag_value('customer_pii', 'name') AS name_col
ON COLUMN name_col;

-- Verify (as a user who is NOT in phi_readers):
--   SELECT first_name, last_name FROM ${catalog}.marts.dim_patients LIMIT 5;
-- Expect REDACTED for both columns.
