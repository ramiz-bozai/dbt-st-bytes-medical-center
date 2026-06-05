with source as (select * from {{ source('synthea_flat', 'raw_careplans') }})
select
    id as care_plan_id,
    {{ cast_to_date("start") }} as care_plan_start_date,
    {{ cast_to_date("stop") }} as care_plan_end_date,
    patient as patient_id,
    encounter as encounter_id,
    code as care_plan_code,
    description as care_plan_description,
    reasoncode as reason_code,
    reasondescription as reason_description,
    stop is null or trim(stop) = '' as is_active,
    {{ cast_to_timestamp("_ingested_at") }} as ingested_at,
    _source_system as source_system,
    _row_hash as row_hash
from source
