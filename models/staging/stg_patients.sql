with source as (
    select * from {{ source('synthea_flat', 'raw_patients') }}
),
renamed as (
    select
        id as patient_id,
        {{ cast_to_date("birthdate") }} as birth_date,
        {{ cast_to_date("deathdate") }} as death_date,
        prefix,
        first as first_name,
        middle as middle_name,
        last as last_name,
        suffix,
        marital as marital_status,
        race,
        ethnicity,
        gender,
        birthplace,
        address,
        city,
        state,
        county,
        fips,
        zip,
        {{ cast_to_double("lat") }} as latitude,
        {{ cast_to_double("lon") }} as longitude,
        {{ cast_to_double("healthcare_expenses") }} as lifetime_healthcare_expenses,
        {{ cast_to_double("healthcare_coverage") }} as lifetime_coverage_amount,
        {{ cast_to_double("income") }} as annual_income,
        {{ cast_to_timestamp("_ingested_at") }} as ingested_at,
        _source_system as source_system,
        _row_hash as row_hash
    from source
)
select * from renamed
