with source as (select * from {{ source('synthea_flat', 'raw_medications') }})
select
    {{ cast_to_timestamp("start") }} as medication_start_at,
    {{ cast_to_timestamp("stop") }} as medication_end_at,
    patient as patient_id,
    payer as payer_id,
    encounter as encounter_id,
    code as medication_code,
    description as medication_description,
    {{ cast_to_double("base_cost") }} as base_cost,
    {{ cast_to_double("payer_coverage") }} as payer_coverage_amount,
    cast({{ adapter.quote('dispenses') }} as int) as dispenses,
    {{ cast_to_double("totalcost") }} as total_cost,
    reasoncode as reason_code,
    reasondescription as reason_description,
    stop is null or trim(stop) = '' as is_active,
    {{ cast_to_timestamp("_ingested_at") }} as ingested_at,
    _source_system as source_system,
    _row_hash as row_hash
from source
