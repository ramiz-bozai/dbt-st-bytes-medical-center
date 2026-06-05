with observations as (
    select *
    from {{ ref('stg_observations') }}
    where observation_category = 'vital-signs'
),

final as (
    select
        patient_id,
        encounter_id,
        observation_at,
        observation_code,
        observation_description,
        {{ cast_to_double('observation_value') }} as observation_value_numeric,
        units
    from observations
    where try_cast(observation_value as double) is not null
)

select * from final
