with vitals as (
    select * from {{ ref('int_observations_vitals') }}
),

ranked as (
    select
        *,
        row_number() over (
            partition by patient_id, observation_code
            order by observation_at desc
        ) as recency_rank
    from vitals
)

select * from ranked where recency_rank = 1
