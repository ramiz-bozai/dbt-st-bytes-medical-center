select
    medication_code, medication_description,
    count(*) as prescription_count,
    count(distinct patient_id) as patient_count,
    sum(total_cost) as total_cost,
    sum(payer_coverage_amount) as total_payer_coverage,
    avg(dispenses) as avg_dispenses
from {{ ref('stg_medications') }}
group by 1,2
order by total_cost desc
