select
    claim_transaction_id, claim_id, patient_id, encounter_id, provider_id,
    transaction_type, amount, payment_method,
    cast(service_start_at as date) as service_date,
    service_start_at, service_end_at, procedure_code, department_id,
    payments, adjustments, outstanding, notes
from {{ ref('stg_claims_transactions') }}
