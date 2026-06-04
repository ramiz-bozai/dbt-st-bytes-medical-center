select
    transaction_type,
    count(*) as line_count,
    sum(amount) as total_amount,
    count(distinct claim_id) as distinct_claims,
    count(distinct patient_id) as distinct_patients
from {{ ref('stg_claims_transactions') }}
group by 1
