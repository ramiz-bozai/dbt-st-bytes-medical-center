with transactions as (
    select * from {{ ref('stg_claims_transactions') }}
),

final as (
    select
        claim_id,
        patient_id,
        count(*) as transaction_line_count,
        sum(case when transaction_type = 'CHARGE' then amount else 0 end) as total_charges,
        sum(case when transaction_type = 'PAYMENT' then amount else 0 end) as total_payments,
        sum(case when transaction_type = 'TRANSFEROUT' then amount else 0 end) as total_transfer_out,
        sum(case when transaction_type = 'TRANSFERIN' then amount else 0 end) as total_transfer_in,
        max(outstanding) as max_outstanding,
        min(cast(service_start_at as date)) as first_service_date,
        max(cast(service_start_at as date)) as last_service_date
    from transactions
    group by 1, 2
)

select * from final
