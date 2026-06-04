with source as (select * from {{ source('bronze', 'raw_immunizations') }})
select
    {{ cast_to_timestamp("date") }} as immunization_at,
    patient as patient_id,
    encounter as encounter_id,
    code as immunization_code,
    description as immunization_description,
    {{ cast_to_double("base_cost") }} as base_cost,
    {{ cast_to_timestamp("_ingested_at") }} as ingested_at,
    _source_system as source_system,
    _row_hash as row_hash
from source
