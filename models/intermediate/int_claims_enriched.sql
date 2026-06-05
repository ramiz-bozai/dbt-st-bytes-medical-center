with claims as (
    select * from {{ ref('stg_claims') }}
),

encounters as (
    select
        encounter_id,
        encounter_class,
        encounter_start_date,
        organization_id,
        provider_id
    from {{ ref('int_encounters_enriched') }}
),

final as (
    select
        c.claim_id,
        c.patient_id,
        c.provider_id,
        c.encounter_id,
        c.service_at,
        cast(c.service_at as date) as service_date,
        c.status_primary,
        c.status_secondary,
        c.outstanding_primary,
        c.outstanding_secondary,
        c.diagnosis1,
        c.diagnosis2,
        c.diagnosis3,
        e.encounter_class,
        e.encounter_start_date,
        e.organization_id
    from claims as c
    left join encounters as e on c.encounter_id = e.encounter_id
)

select * from final
