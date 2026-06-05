with encounters as (
    select encounter_id, patient_id from {{ ref('stg_encounters') }}
),

conditions as (
    select encounter_id, count(*) as condition_count
    from {{ ref('stg_conditions') }}
    group by 1
),

procedures as (
    select encounter_id, count(*) as procedure_count, sum(base_cost) as procedure_cost
    from {{ ref('stg_procedures') }}
    group by 1
),

observations as (
    select encounter_id, count(*) as observation_count
    from {{ ref('stg_observations') }}
    where encounter_id is not null
    group by 1
),

medications as (
    select encounter_id, count(*) as medication_count, sum(total_cost) as medication_cost
    from {{ ref('stg_medications') }}
    group by 1
),

immunizations as (
    select encounter_id, count(*) as immunization_count
    from {{ ref('stg_immunizations') }}
    group by 1
),

final as (
    select
        e.encounter_id,
        e.patient_id,
        coalesce(c.condition_count, 0) as condition_count,
        coalesce(p.procedure_count, 0) as procedure_count,
        coalesce(p.procedure_cost, 0) as procedure_cost,
        coalesce(o.observation_count, 0) as observation_count,
        coalesce(m.medication_count, 0) as medication_count,
        coalesce(m.medication_cost, 0) as medication_cost,
        coalesce(i.immunization_count, 0) as immunization_count
    from encounters as e
    left join conditions as c on e.encounter_id = c.encounter_id
    left join procedures as p on e.encounter_id = p.encounter_id
    left join observations as o on e.encounter_id = o.encounter_id
    left join medications as m on e.encounter_id = m.encounter_id
    left join immunizations as i on e.encounter_id = i.encounter_id
)

select * from final
