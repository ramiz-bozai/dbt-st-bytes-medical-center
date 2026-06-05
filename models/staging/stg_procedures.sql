select
    {{ cast_to_timestamp("start") }} as procedure_start_at,
    {{ cast_to_timestamp("stop") }} as procedure_end_at,
    patient as patient_id,
    encounter as encounter_id,
    system as code_system,
    code as procedure_code,
    description as procedure_description,
    {{ cast_to_double("base_cost") }} as base_cost,
    reasoncode as reason_code,
    reasondescription as reason_description,
    {{ cast_to_timestamp("_ingested_at") }} as ingested_at,
    _source_system as source_system,
    _row_hash as row_hash
{{ stream_read_synthea_csv('procedures.csv') }}
