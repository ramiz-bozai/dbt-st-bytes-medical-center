with source as (select * from {{ source('bronze', 'raw_supplies') }})
select
    {{ cast_to_date("date") }} as supply_date,
    patient as patient_id,
    encounter as encounter_id,
    code as supply_code,
    description as supply_description,
    cast({{ adapter.quote('quantity') }} as int) as quantity,
    {{ cast_to_timestamp("_ingested_at") }} as ingested_at,
    _source_system as source_system,
    _row_hash as row_hash
from source
