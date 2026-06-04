with source as (select * from {{ source('bronze', 'raw_payers') }})
select
    id as payer_id,
    name as payer_name,
    ownership,
    {{ cast_to_double("amount_covered") }} as amount_covered,
    {{ cast_to_double("amount_uncovered") }} as amount_uncovered,
    {{ cast_to_double("revenue") }} as revenue,
    cast({{ adapter.quote('covered_encounters') }} as int) as covered_encounters,
    cast({{ adapter.quote('uncovered_encounters') }} as int) as uncovered_encounters,
    cast({{ adapter.quote('unique_customers') }} as int) as unique_customers,
    {{ cast_to_double("qols_avg") }} as quality_of_life_avg,
    cast({{ adapter.quote('member_months') }} as int) as member_months,
    {{ cast_to_timestamp("_ingested_at") }} as ingested_at,
    _source_system as source_system,
    _row_hash as row_hash
from source
