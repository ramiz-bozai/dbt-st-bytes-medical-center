with source as (select * from {{ source('bronze', 'raw_imaging_studies') }})
select
    id as imaging_study_id,
    {{ cast_to_timestamp("date") }} as study_at,
    patient as patient_id,
    encounter as encounter_id,
    series_uid,
    bodysite_code,
    bodysite_description,
    modality_code,
    modality_description,
    instance_uid,
    sop_code,
    sop_description,
    procedure_code,
    {{ cast_to_timestamp("_ingested_at") }} as ingested_at,
    _source_system as source_system,
    _row_hash as row_hash
from source
