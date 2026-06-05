{{ config(
    materialized='materialized_view',
) }}

-- BI dashboard layer: revenue-cycle KPIs by transaction type with network share.
-- Refreshed after upstream models rebuild; ideal for executive revenue-cycle tiles.
with base as (
    select
        transaction_type,
        count(*) as line_count,
        sum(amount) as total_amount,
        count(distinct claim_id) as distinct_claims,
        count(distinct patient_id) as distinct_patients
    from {{ ref('stg_claims_transactions') }}
    group by 1
),

totals as (
    select sum(total_amount) as network_total_amount
    from base
)

select
    b.transaction_type,
    b.line_count,
    b.total_amount,
    b.distinct_claims,
    b.distinct_patients,
    round(b.total_amount / nullif(b.line_count, 0), 2) as avg_amount_per_line,
    round(100.0 * b.total_amount / nullif(t.network_total_amount, 0), 2) as pct_of_network_amount,
    rank() over (order by abs(b.total_amount) desc) as amount_rank
from base as b
cross join totals as t
