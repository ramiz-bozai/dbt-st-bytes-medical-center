with source as (select * from {{ source('bronze', 'raw_encounters') }})
select
    id as encounter_id,
    {{ cast_to_timestamp("start") }} as encounter_start_at,
    {{ cast_to_timestamp("stop") }} as encounter_end_at,
    patient as patient_id,
    organization as organization_id,
    provider as provider_id,
    payer as payer_id,
    encounterclass as encounter_class,
    code as encounter_code,
    description as encounter_description,
    {{ cast_to_double("base_encounter_cost") }} as base_encounter_cost,
    {{ cast_to_double("total_claim_cost") }} as total_claim_cost,
    {{ cast_to_double("payer_coverage") }} as payer_coverage_amount,
    reasoncode as reason_code,
    reasondescription as reason_description,
    {{ cast_to_timestamp("_ingested_at") }} as ingested_at,
    _source_system as source_system,
    _row_hash as row_hash
from source
