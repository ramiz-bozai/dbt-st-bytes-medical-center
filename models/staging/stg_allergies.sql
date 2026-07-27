select
    {{ cast_to_date("start") }} as allergy_start_date,
    {{ cast_to_date("stop") }} as allergy_end_date,
    patient as patient_id,
    encounter as encounter_id,
    code as allergy_code,
    system as code_system,
    description as allergy_description,
    type as allergy_type,
    category as allergy_category,
    stop is null or trim(stop) = '' as is_active,
    {{ cast_to_timestamp("_ingested_at") }} as ingested_at,
    _source_system as source_system,
    _row_hash as row_hash
{{ stream_read_synthea_csv('allergies.csv') }}
