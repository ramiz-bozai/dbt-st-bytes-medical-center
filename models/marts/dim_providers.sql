select
    provider_id, organization_id, provider_name, gender, specialty,
    city, state, zip, lifetime_encounters, lifetime_procedures
from {{ ref('stg_providers') }}
