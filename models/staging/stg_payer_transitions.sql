with source as (select * from {{ source('synthea_flat', 'raw_payer_transitions') }})
select
    patient as patient_id,
    memberid as member_id,
    {{ cast_to_timestamp("start_date") }} as coverage_start_at,
    {{ cast_to_timestamp("end_date") }} as coverage_end_at,
    payer as payer_id,
    secondary_payer as secondary_payer_id,
    plan_ownership,
    owner_name,
    {{ cast_to_timestamp("_ingested_at") }} as ingested_at,
    _source_system as source_system,
    _row_hash as row_hash
from source
