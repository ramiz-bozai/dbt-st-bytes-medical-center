with source as (select * from {{ source('bronze', 'raw_providers') }})
select
    id as provider_id,
    organization as organization_id,
    name as provider_name,
    gender,
    speciality as specialty,
    address, city, state, zip,
    {{ cast_to_double("lat") }} as latitude,
    {{ cast_to_double("lon") }} as longitude,
    cast({{ adapter.quote('encounters') }} as int) as lifetime_encounters,
    cast({{ adapter.quote('procedures') }} as int) as lifetime_procedures,
    {{ cast_to_timestamp("_ingested_at") }} as ingested_at,
    _source_system as source_system,
    _row_hash as row_hash
from source
