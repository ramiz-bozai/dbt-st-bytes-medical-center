select
    immunization_code, immunization_description,
    count(*) as dose_count,
    count(distinct patient_id) as patient_count,
    sum(base_cost) as total_cost
from {{ ref('stg_immunizations') }}
group by 1,2
