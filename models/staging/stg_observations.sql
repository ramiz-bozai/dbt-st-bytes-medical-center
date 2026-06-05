select
    {{ cast_to_timestamp("date") }} as observation_at,
    patient as patient_id,
    encounter as encounter_id,
    nullif(trim(category), '') as observation_category,
    code as observation_code,
    description as observation_description,
    value as observation_value,
    units,
    type as value_type,
    {{ cast_to_timestamp("_ingested_at") }} as ingested_at,
    _source_system as source_system,
    _row_hash as row_hash
{{ stream_read_synthea_csv('observations.csv') }}
