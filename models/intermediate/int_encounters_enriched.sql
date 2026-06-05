with encounters as (
    select * from {{ ref('stg_encounters') }}
),

patients as (
    select patient_id, age_years, age_band, gender, state, is_alive
    from {{ ref('int_patient_demographics') }}
),

providers as (
    select provider_id, provider_name, specialty, organization_id
    from {{ ref('stg_providers') }}
),

organizations as (
    select organization_id, organization_name, city as org_city, state as org_state
    from {{ ref('stg_organizations') }}
),

payers as (
    select payer_id, payer_name, ownership as payer_ownership
    from {{ ref('stg_payers') }}
),

final as (
    select
        e.encounter_id,
        e.patient_id,
        e.provider_id,
        e.organization_id,
        e.payer_id,
        e.encounter_class,
        e.encounter_code,
        e.encounter_description,
        cast(e.encounter_start_at as date) as encounter_start_date,
        e.encounter_start_at,
        e.encounter_end_at,
        datediff(minute, e.encounter_start_at, e.encounter_end_at) as encounter_duration_minutes,
        e.base_encounter_cost,
        e.total_claim_cost,
        e.payer_coverage_amount,
        e.reason_code,
        e.reason_description,
        p.age_years,
        p.age_band,
        p.gender as patient_gender,
        p.state as patient_state,
        p.is_alive,
        pr.provider_name,
        pr.specialty as provider_specialty,
        o.organization_name,
        o.org_city,
        o.org_state,
        py.payer_name,
        py.payer_ownership
    from encounters as e
    left join patients as p on e.patient_id = p.patient_id
    left join providers as pr on e.provider_id = pr.provider_id
    left join organizations as o on e.organization_id = o.organization_id
    left join payers as py on e.payer_id = py.payer_id
)

select * from final
