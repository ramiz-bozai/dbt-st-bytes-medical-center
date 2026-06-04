with demo as (select * from {{ ref('int_patient_demographics') }}),
enc as (
    select patient_id,
        count(*) as encounter_count,
        count(distinct encounter_class) as distinct_encounter_classes,
        min(encounter_start_date) as first_encounter_date,
        max(encounter_start_date) as last_encounter_date,
        sum(total_claim_cost) as total_encounter_claim_cost,
        sum(base_encounter_cost) as total_base_encounter_cost
    from {{ ref('int_encounters_enriched') }}
    group by 1
),
conds as (select * from {{ ref('int_patient_active_conditions') }}),
claims as (
    select patient_id, count(*) as claim_count, sum(total_charges) as lifetime_charges,
        sum(total_payments) as lifetime_payments
    from {{ ref('int_claim_financials') }}
    group by 1
)
select d.*, e.encounter_count, e.distinct_encounter_classes,
    e.first_encounter_date, e.last_encounter_date,
    e.total_encounter_claim_cost, e.total_base_encounter_cost,
    coalesce(c.active_condition_count, 0) as active_condition_count,
    cl.claim_count, cl.lifetime_charges, cl.lifetime_payments
from demo d
left join enc e on d.patient_id = e.patient_id
left join conds c on d.patient_id = c.patient_id
left join claims cl on d.patient_id = cl.patient_id
