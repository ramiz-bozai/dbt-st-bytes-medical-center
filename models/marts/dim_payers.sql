select payer_id, payer_name, ownership, amount_covered, amount_uncovered,
    revenue, covered_encounters, uncovered_encounters, unique_customers,
    quality_of_life_avg, member_months
from {{ ref('stg_payers') }}
