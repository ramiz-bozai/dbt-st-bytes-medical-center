# Databricks notebook source
# MAGIC %md
# MAGIC # St. Bytes Medical Center — bronze (Spark Declarative Pipelines)
# MAGIC
# MAGIC **Practice path:** ingest Synthea CSVs from cloud storage into `raw_*` tables.
# MAGIC Table names match `models/staging/__sources.yml` (dbt `source('bronze', ...)`).
# MAGIC
# MAGIC **Lab path:** use `dbt seed` instead — do not double-load in the same environment.

# COMMAND ----------

import dlt
from pyspark.sql import functions as F

# --- CONFIG (edit for your workspace) ---
CATALOG = "st_bytes"
BRONZE_SCHEMA = "raw"
BATCH_PATH = "abfss://<container>@<account>.dfs.core.windows.net/st_bytes_medical_center"
# Optional streaming inbox for claim transaction appends:
STREAM_CLAIM_TXN_PATH = "abfss://<container>@<account>.dfs.core.windows.net/streaming/claims_transactions"

AUDIT_COLS = [
    F.current_timestamp().alias("_ingested_at"),
    F.lit("synthea").alias("_source_system"),
]

# COMMAND ----------

TABLES = [
    "patients",
    "providers",
    "organizations",
    "payers",
    "encounters",
    "claims",
    "claims_transactions",
    "conditions",
    "procedures",
    "observations",
    "medications",
    "immunizations",
    "allergies",
    "careplans",
    "devices",
    "supplies",
    "imaging_studies",
    "payer_transitions",
]


def _read_batch_csv(name: str):
    path = f"{BATCH_PATH}/{name}.csv"
    df = (
        spark.read.format("csv")
        .option("header", True)
        .option("inferSchema", True)
        .load(path)
    )
    row_hash = F.sha2(
        F.concat_ws(
            "|",
            *[F.coalesce(F.col(c).cast("string"), F.lit("")) for c in df.columns],
        ),
        256,
    )
    return df.select(*df.columns, *AUDIT_COLS, row_hash.alias("_row_hash"))


def _register_bronze_table(table: str):
    raw_name = f"raw_{table}"

    @dlt.table(
        name=raw_name,
        comment=f"Bronze — Synthea {table} (batch)",
        table_properties={"quality": "bronze", "domain": "healthcare"},
    )
    def _batch_table():
        return _read_batch_csv(table)

    return _batch_table


for _table in TABLES:
    _register_bronze_table(_table)


# COMMAND ----------
# MAGIC %md
# MAGIC ## Optional: streaming claim transactions
# MAGIC
# MAGIC Uncomment to append late-arriving `claims_transactions` rows via Auto Loader.

# COMMAND ----------

# @dlt.table(name="raw_claims_transactions_stream", comment="Streaming claim txn append")
# def raw_claims_transactions_stream():
#     return (
#         spark.readStream.format("cloudFiles")
#         .option("cloudFiles.format", "csv")
#         .option("header", True)
#         .load(STREAM_CLAIM_TXN_PATH)
#         .select(*AUDIT_COLS, F.sha2(F.concat_ws("|", *[_ for _ in []]), 256).alias("_row_hash"))
#     )
