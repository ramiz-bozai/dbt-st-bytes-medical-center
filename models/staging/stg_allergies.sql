{{ config(materialized='table') }}

with source as (select * from {{ source('postgres_allergies', 'raw_allergies') }})
select
    start as allergy_start_date,
    stop as allergy_end_date,
    cast(patient as string) as patient_id,
    cast(encounter as string) as encounter_id,
    cast(code as bigint) as allergy_code,
    cast(`system` as string) as code_system,
    cast(description as string) as allergy_description,
    cast(`type` as string) as allergy_type,
    cast(category as string) as allergy_category,
    stop is null as is_active,
    {{ cast_to_timestamp("_ingested_at") }} as ingested_at,
    cast(_source_system as string) as source_system,
    cast(_row_hash as string) as row_hash
from source
