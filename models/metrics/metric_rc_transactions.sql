{{ config(
    materialized='metric_view',
    description='Revenue cycle transaction-line metrics for charges, payments, adjustments, and outstanding balances.',
) }}

version: 1.1
comment: St. Bytes revenue cycle — claim transaction lines (charges, payments, transfers).
source: {{ ref('fct_claim_transactions') }}
dimensions:
  - name: service_date
    expr: service_date
    comment: Calendar date the clinical service associated with the transaction line was performed.
    display_name: Service Date
  - name: transaction_type
    expr: transaction_type
    comment: Revenue-cycle line type (for example CHARGE, PAYMENT, TRANSFERIN, TRANSFEROUT).
    display_name: Transaction Type
  - name: payment_method
    expr: payment_method
    comment: Payment method recorded on the transaction line, when applicable.
    display_name: Payment Method
  - name: procedure_code
    expr: procedure_code
    comment: Procedure or billing code associated with the transaction line.
    display_name: Procedure Code
measures:
  - name: transaction_line_count
    expr: COUNT(1)
    comment: Number of claim transaction lines.
    display_name: Transaction Line Count
  - name: total_amount
    expr: SUM(amount)
    comment: Sum of transaction amounts across all line types.
    display_name: Total Amount
  - name: total_payments
    expr: SUM(payments)
    comment: Sum of payment amounts posted on transaction lines.
    display_name: Total Payments
  - name: total_adjustments
    expr: SUM(adjustments)
    comment: Sum of adjustment amounts applied on transaction lines.
    display_name: Total Adjustments
  - name: total_outstanding
    expr: SUM(outstanding)
    comment: Sum of outstanding balances remaining on transaction lines.
    display_name: Total Outstanding
  - name: distinct_claims
    expr: COUNT(DISTINCT claim_id)
    comment: Count of unique claims represented in the selected transaction lines.
    display_name: Distinct Claims
  - name: distinct_patients
    expr: COUNT(DISTINCT patient_id)
    comment: Count of unique patients represented in the selected transaction lines.
    display_name: Distinct Patients
