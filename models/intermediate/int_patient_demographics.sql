with patients as (
    select * from {{ ref('stg_patients') }}
),

final as (
    select
        patient_id,
        birth_date,
        death_date,
        first_name,
        last_name,
        gender,
        race,
        ethnicity,
        city,
        state,
        zip,
        annual_income,
        lifetime_healthcare_expenses,
        lifetime_coverage_amount,
        death_date is null as is_alive,
        datediff(year, birth_date, coalesce(death_date, current_date())) as age_years,
        case
            when death_date is not null then 'deceased'
            when datediff(year, birth_date, current_date()) < 18 then 'pediatric'
            when datediff(year, birth_date, current_date()) >= 65 then 'senior'
            else 'adult'
        end as age_band
    from patients
)

select * from final
