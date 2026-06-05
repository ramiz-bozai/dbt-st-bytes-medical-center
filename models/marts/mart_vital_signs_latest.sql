select
    patient_id, observation_code, observation_description,
    observation_value_numeric, units, observation_at
from {{ ref('int_latest_vitals') }}
