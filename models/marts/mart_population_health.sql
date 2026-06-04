select
    age_band, gender, state,
    count(*) as patient_count,
    sum(case when is_alive then 1 else 0 end) as alive_count,
    avg(age_years) as avg_age,
    avg(lifetime_healthcare_expenses) as avg_lifetime_expenses,
    avg(annual_income) as avg_annual_income
from {{ ref('int_patient_demographics') }}
group by 1,2,3
