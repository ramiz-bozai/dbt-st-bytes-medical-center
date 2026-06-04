-- Run after: dbt run --select mart_encounter_class_distribution
-- Unity Catalog metrics view for BI semantic layer

CREATE OR REPLACE VIEW encounter_volume_metrics AS
SELECT
    encounter_class,
    encounter_count,
    patient_count,
    avg_duration_minutes,
    total_claim_cost,
    avg_claim_cost
FROM mart_encounter_class_distribution;
