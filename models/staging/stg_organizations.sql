with source as (select * from {{ source('bronze', 'raw_organizations') }})
select
    id as organization_id,
    name as organization_name,
    address, city, state, zip,
    {{ cast_to_double("lat") }} as latitude,
    {{ cast_to_double("lon") }} as longitude,
    phone,
    {{ cast_to_double("revenue") }} as revenue,
    cast({{ adapter.quote('utilization') }} as int) as utilization,
    {{ cast_to_timestamp("_ingested_at") }} as ingested_at,
    _source_system as source_system,
    _row_hash as row_hash
from source
