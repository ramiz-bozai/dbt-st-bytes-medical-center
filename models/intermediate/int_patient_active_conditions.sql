with conditions as (
    select * from {{ ref('stg_conditions') }}
    where is_active
),

final as (
    select
        patient_id,
        count(distinct condition_code) as active_condition_count,
        collect_set(condition_description) as active_condition_descriptions
    from conditions
    group by 1
)

select * from final
