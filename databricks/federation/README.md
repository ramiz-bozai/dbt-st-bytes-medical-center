# Lakehouse Federation

| File | Purpose |
|------|---------|
| `01_lakehouse_federation_setup.sql` | Connection, foreign catalog, grants (commented templates) |

**Not used by dbt today.** `stg_allergies` previously read a federated Postgres catalog; it now
streams `allergies.csv` from the UC volume like every other staging model, so no model references a
foreign catalog and `models/staging/__sources.yml` defines no sources.

Keep this as a reference pattern for when genuinely external reference data needs to be joined in
(payer metadata, provider registries, marketplace datasets). The SQL is a commented-out template —
fill in your own connection, host, and secret before running any of it.
