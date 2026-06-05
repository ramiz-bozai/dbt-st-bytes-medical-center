with claims as (
    select * from {{ ref('int_claims_enriched') }}
),

financials as (
    select * from {{ ref('int_claim_financials') }}
),

final as (
    select
        c.*,
        f.transaction_line_count,
        f.total_charges,
        f.total_payments,
        f.total_transfer_out,
        f.total_transfer_in,
        f.max_outstanding,
        coalesce(f.total_charges, 0) - coalesce(f.total_payments, 0) as net_balance
    from claims as c
    left join financials as f on c.claim_id = f.claim_id
)

select * from final
