select
    e.encounter_id, e.patient_id, e.encounter_class, e.encounter_start_date,
    e.organization_name, e.provider_name, e.payer_name,
    e.base_encounter_cost, e.total_claim_cost, e.payer_coverage_amount,
    c.condition_count, c.procedure_count, c.procedure_cost,
    c.medication_count, c.medication_cost, c.observation_count
from {{ ref('int_encounters_enriched') }} e
left join {{ ref('int_encounter_clinical_counts') }} c on e.encounter_id = c.encounter_id
