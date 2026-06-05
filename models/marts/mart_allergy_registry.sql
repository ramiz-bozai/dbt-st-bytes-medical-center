select
    patient_id, allergy_code, allergy_description, allergy_category, allergy_type,
    allergy_start_date, is_active
from {{ ref('stg_allergies') }}
