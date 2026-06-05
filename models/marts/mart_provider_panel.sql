select
    p.provider_id, p.provider_name, p.specialty, p.organization_id,
    o.organization_name,
    count(distinct e.encounter_id) as encounter_count,
    count(distinct e.patient_id) as distinct_patients,
    sum(e.total_claim_cost) as total_claim_cost,
    avg(e.encounter_duration_minutes) as avg_encounter_minutes
from {{ ref('stg_providers') }} p
left join {{ ref('int_encounters_enriched') }} e on p.provider_id = e.provider_id
left join {{ ref('stg_organizations') }} o on p.organization_id = o.organization_id
group by 1,2,3,4,5
