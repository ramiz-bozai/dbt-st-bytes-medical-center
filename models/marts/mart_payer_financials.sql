select
    py.payer_id, py.payer_name, py.ownership,
    py.amount_covered, py.amount_uncovered, py.revenue,
    count(distinct e.encounter_id) as encounter_count,
    sum(e.payer_coverage_amount) as total_payer_coverage_on_encounters,
    sum(m.payer_coverage_amount) as total_medication_coverage
from {{ ref('stg_payers') }} py
left join {{ ref('int_encounters_enriched') }} e on py.payer_id = e.payer_id
left join {{ ref('stg_medications') }} m on py.payer_id = m.payer_id
group by 1,2,3,4,5,6
