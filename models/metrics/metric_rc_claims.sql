{{ config(
    materialized='metric_view',
    description='Revenue cycle claim-level financial metrics with status and encounter context.',
) }}

version: 1.1
comment: St. Bytes revenue cycle — claim financial rollups (charges, payments, outstanding, net balance).
source: {{ ref('fct_claims') }}
dimensions:
  - name: service_date
    expr: service_date
    comment: Calendar date of service on the claim.
    display_name: Service Date
  - name: status_primary
    expr: status_primary
    comment: Primary billing or adjudication status on the claim.
    display_name: Primary Claim Status
  - name: status_secondary
    expr: status_secondary
    comment: Secondary billing or adjudication status on the claim.
    display_name: Secondary Claim Status
  - name: encounter_class
    expr: encounter_class
    comment: Care setting for the linked encounter (for example ambulatory, emergency, inpatient).
    display_name: Encounter Class
measures:
  - name: claim_count
    expr: COUNT(1)
    comment: Number of claims.
    display_name: Claim Count
  - name: distinct_patients
    expr: COUNT(DISTINCT patient_id)
    comment: Count of unique patients with claims in the selection.
    display_name: Distinct Patients
  - name: total_charges
    expr: SUM(total_charges)
    comment: Sum of all charges rolled up to the claim from transaction lines.
    display_name: Total Charges
  - name: total_payments
    expr: SUM(total_payments)
    comment: Sum of all payments rolled up to the claim from transaction lines.
    display_name: Total Payments
  - name: total_outstanding_primary
    expr: SUM(outstanding_primary)
    comment: Sum of primary-payer outstanding balances on claims.
    display_name: Total Outstanding (Primary)
  - name: total_outstanding_secondary
    expr: SUM(outstanding_secondary)
    comment: Sum of secondary-payer outstanding balances on claims.
    display_name: Total Outstanding (Secondary)
  - name: total_net_balance
    expr: SUM(net_balance)
    comment: Sum of net balance (total charges minus total payments) across claims.
    display_name: Total Net Balance
  - name: avg_transaction_lines_per_claim
    expr: AVG(transaction_line_count)
    comment: Average number of transaction lines per claim.
    display_name: Avg Transaction Lines per Claim
