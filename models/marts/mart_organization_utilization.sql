select
    o.organization_id, o.organization_name, o.city, o.state,
    o.utilization as reported_utilization,
    count(distinct e.encounter_id) as encounter_count,
    count(distinct e.patient_id) as distinct_patients,
    count(distinct e.provider_id) as distinct_providers,
    sum(e.total_claim_cost) as total_claim_cost
from {{ ref('stg_organizations') }} o
left join {{ ref('int_encounters_enriched') }} e on o.organization_id = e.organization_id
group by 1,2,3,4,5
