with source as (select * from {{ source('synthea_flat', 'raw_devices') }})
select
    {{ cast_to_timestamp("start") }} as device_start_at,
    {{ cast_to_timestamp("stop") }} as device_end_at,
    patient as patient_id,
    encounter as encounter_id,
    code as device_code,
    description as device_description,
    udi as device_udi,
    stop is null or trim(stop) = '' as is_in_use,
    {{ cast_to_timestamp("_ingested_at") }} as ingested_at,
    _source_system as source_system,
    _row_hash as row_hash
from source
