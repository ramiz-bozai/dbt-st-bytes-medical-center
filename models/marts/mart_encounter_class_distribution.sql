select
    encounter_class,
    count(*) as encounter_count,
    count(distinct patient_id) as patient_count,
    avg(encounter_duration_minutes) as avg_duration_minutes,
    sum(total_claim_cost) as total_claim_cost,
    avg(total_claim_cost) as avg_claim_cost
from {{ ref('int_encounters_enriched') }}
group by 1
