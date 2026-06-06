{{ config(
    materialized='metric_view',
    description='Revenue cycle encounter cost metrics with payer coverage and clinical cost drivers.',
) }}

version: 1.1
comment: St. Bytes revenue cycle — encounter-level claim cost, coverage, and clinical cost components.
source: {{ ref('mart_encounter_cost_analysis') }}
dimensions:
  - name: encounter_start_date
    expr: encounter_start_date
    comment: Calendar date the clinical encounter began.
    display_name: Encounter Start Date
  - name: encounter_class
    expr: encounter_class
    comment: Care setting for the encounter (for example ambulatory, emergency, inpatient).
    display_name: Encounter Class
  - name: organization_name
    expr: organization_name
    comment: Healthcare organization or facility where the encounter occurred.
    display_name: Organization
  - name: provider_name
    expr: provider_name
    comment: Attending or billing provider for the encounter.
    display_name: Provider
  - name: payer_name
    expr: payer_name
    comment: Primary payer associated with the encounter.
    display_name: Payer
measures:
  - name: encounter_count
    expr: COUNT(1)
    comment: Number of clinical encounters.
    display_name: Encounter Count
  - name: distinct_patients
    expr: COUNT(DISTINCT patient_id)
    comment: Count of unique patients with encounters in the selection.
    display_name: Distinct Patients
  - name: total_claim_cost
    expr: SUM(total_claim_cost)
    comment: Sum of total claim cost attributed to encounters.
    display_name: Total Claim Cost
  - name: total_base_encounter_cost
    expr: SUM(base_encounter_cost)
    comment: Sum of base encounter cost before additional claim components.
    display_name: Total Base Encounter Cost
  - name: total_payer_coverage
    expr: SUM(payer_coverage_amount)
    comment: Sum of payer coverage dollars applied to encounters.
    display_name: Total Payer Coverage
  - name: total_procedure_cost
    expr: SUM(procedure_cost)
    comment: Sum of procedure costs linked to encounters.
    display_name: Total Procedure Cost
  - name: total_medication_cost
    expr: SUM(medication_cost)
    comment: Sum of medication costs linked to encounters.
    display_name: Total Medication Cost
  - name: avg_claim_cost_per_encounter
    expr: AVG(total_claim_cost)
    comment: Average total claim cost per encounter.
    display_name: Avg Claim Cost per Encounter
