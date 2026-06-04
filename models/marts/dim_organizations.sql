select organization_id, organization_name, address, city, state, zip,
    latitude, longitude, phone, revenue, utilization
from {{ ref('stg_organizations') }}
