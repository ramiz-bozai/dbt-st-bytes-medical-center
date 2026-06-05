{{ config(
    materialized='materialized_view',
) }}

-- BI dashboard layer: pre-aggregated encounter mix by class with share-of-total.
-- Refreshed after upstream models rebuild; point dashboards here for low-latency filters.
with base as (
    select
        encounter_class,
        count(*) as encounter_count,
        count(distinct patient_id) as patient_count,
        avg(encounter_duration_minutes) as avg_duration_minutes,
        sum(total_claim_cost) as total_claim_cost,
        avg(total_claim_cost) as avg_claim_cost
    from {{ ref('int_encounters_enriched') }}
    group by 1
),

totals as (
    select sum(encounter_count) as total_encounters
    from base
)

select
    b.encounter_class,
    b.encounter_count,
    b.patient_count,
    b.avg_duration_minutes,
    b.total_claim_cost,
    b.avg_claim_cost,
    round(100.0 * b.encounter_count / nullif(t.total_encounters, 0), 2) as pct_of_encounters,
    rank() over (order by b.encounter_count desc) as encounter_volume_rank
from base as b
cross join totals as t
