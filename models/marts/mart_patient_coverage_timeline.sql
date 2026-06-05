select
    patient_id, payer_id, member_id,
    cast(coverage_start_at as date) as coverage_start_date,
    cast(coverage_end_at as date) as coverage_end_date,
    plan_ownership, owner_name
from {{ ref('stg_payer_transitions') }}
