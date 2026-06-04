# St. Bytes Medical Center — dbt analytics

dbt project for **Synthea** synthetic healthcare data at St. Bytes Medical Center (Massachusetts), loaded from `seeds/st_bytes_medical_center/`.

## Medallion layout

| Layer | Location | Objects |
|-------|----------|---------|
| **Bronze** | `seeds/` → `raw.raw_*` | 18 source tables |
| **Silver** | `models/staging/`, `models/intermediate/` | `stg_*`, `int_*` views |
| **Gold** | `models/marts/` | `dim_*`, `fct_*`, `mart_*` tables |

See [docs/data_profile_st_bytes.md](docs/data_profile_st_bytes.md) for the data survey and [docs/platform_guide.md](docs/platform_guide.md) for the Databricks demo (SDP bronze in practice, `dbt seed` in the lab).

## Quick start

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp profiles.yml.example profiles.yml
# set DATABRICKS_* env vars

dbt deps
dbt seed --full-refresh
dbt run
dbt test
```

Update `profiles.yml` profile name to **`st_bytes_medical_center`** (replaces the prior NBA project name).

## Gold analytics (examples)

- **Patient 360:** `mart_patient_summary`, `mart_vital_signs_latest`
- **Operations:** `mart_encounter_class_distribution`, `mart_provider_panel`, `mart_organization_utilization`
- **Revenue cycle:** `mart_revenue_cycle`, `mart_claims_aging`, `fct_claim_transactions`
- **Clinical:** `mart_chronic_conditions`, `mart_medication_utilization`, `mart_immunization_coverage`
- **Population:** `mart_population_health`

## Data source

Synthetic data generated with [Synthea](https://github.com/synthetichealth/synthea). Not for production PHI.
