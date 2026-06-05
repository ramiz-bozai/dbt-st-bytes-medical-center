with source as (select * from {{ source('synthea_flat', 'raw_conditions') }})
select
    {{ cast_to_date("start") }} as condition_start_date,
    {{ cast_to_date("stop") }} as condition_end_date,
    patient as patient_id,
    encounter as encounter_id,
    system as code_system,
    code as condition_code,
    description as condition_description,
    stop is null or trim(stop) = '' as is_active,
    {{ cast_to_timestamp("_ingested_at") }} as ingested_at,
    _source_system as source_system,
    _row_hash as row_hash
from source
