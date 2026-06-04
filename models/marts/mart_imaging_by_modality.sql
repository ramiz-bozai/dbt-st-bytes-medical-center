select
    modality_code, modality_description, bodysite_description,
    count(*) as instance_count,
    count(distinct patient_id) as patient_count,
    count(distinct encounter_id) as encounter_count
from {{ ref('stg_imaging_studies') }}
group by 1,2,3
