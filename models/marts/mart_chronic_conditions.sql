select
    condition_code, condition_description,
    count(distinct patient_id) as patient_count,
    count(*) as record_count,
    sum(case when is_active then 1 else 0 end) as active_record_count
from {{ ref('stg_conditions') }}
group by 1,2
order by patient_count desc
