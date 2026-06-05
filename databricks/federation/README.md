# Lakehouse Federation

| File | Purpose |
|------|---------|
| `01_lakehouse_federation_setup.sql` | Connection, foreign catalog, grants (templates) |

**dbt:** `models/staging/federation_sources.yml` + `stg_fifa_rankings.sql` → `teams_with_rankings` mart.

**Seed stand-in:** `seeds/world-cup/raw_fifa_rankings.csv` loaded into schema `federation` via `dbt_project.yml`.
