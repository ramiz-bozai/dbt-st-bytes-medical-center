# St. Bytes Medical Center — raw data profile

**Source:** Synthea synthetic FHIR export (`_source_system = synthea`)  
**Bronze location:** bundled under `seeds/st_bytes_medical_center/*.csv`, then uploaded to a
Unity Catalog volume for staging `read_files()` ingestion
**Profiled:** row counts, keys, null rates (sample), and domain groupings

## Volume summary

| Table | Rows | Grain | Primary keys / links |
|-------|------|-------|----------------------|
| patients | 111 | 1 row / patient | `id` |
| providers | 291 | 1 row / provider | `id` → `organization` |
| organizations | 291 | 1 row / facility | `id` |
| payers | 10 | 1 row / payer | `id` |
| encounters | 5,745 | 1 row / visit | `id`; FK `patient`, `provider`, `organization`, `payer` |
| claims | 9,995 | 1 row / claim | `id`; `patientid`, `appointmentid` ≈ encounter |
| claims_transactions | 95,313 | 1 row / financial line | `id`; FK `claimid`, `patientid` |
| conditions | 3,541 | 1 row / diagnosis episode | FK `patient`, `encounter` |
| procedures | 16,045 | 1 row / procedure | FK `patient`, `encounter` |
| observations | 65,503 | 1 row / observation | FK `patient`, `encounter`; `category` (lab, vitals, survey) |
| medications | 4,250 | 1 row / med order | FK `patient`, `encounter`, `payer` |
| immunizations | 1,576 | 1 row / immunization | FK `patient`, `encounter` |
| allergies | 91 | 1 row / allergy | FK `patient`, `encounter` |
| careplans | 352 | 1 row / care plan | `id`; FK `patient`, `encounter` |
| devices | 609 | 1 row / device use | FK `patient`, `encounter` |
| supplies | 2,482 | 1 row / supply | FK `patient`, `encounter` |
| imaging_studies | 23,047 | 1 row / DICOM instance | `id`; FK `patient`, `encounter`; high cardinality `instance_uid` |
| payer_transitions | 4,154 | coverage spans | FK `patient`, `payer` |

## Lineage hub

```text
patients ──┬── encounters ──┬── conditions / procedures / observations / …
           │                └── claims (appointmentid = encounter.id)
           └── payer_transitions ── payers
providers ── organizations
```

## Notable distributions

- **Encounter class:** ambulatory (55%), wellness (23%), outpatient, emergency, urgent care, inpatient, home, SNF, virtual, hospice.
- **Observation category:** laboratory (41%), survey (32%), vital-signs (20%), social-history, exam.
- **Claim transaction type:** PAYMENT (37%), CHARGE (29%), TRANSFEROUT/IN (17% each).

## Data quality notes

- All tables include `_ingested_at`, `_source_system`, `_row_hash` (bronze audit columns).
- **PII on patients:** `ssn`, `drivers`, `passport` — excluded from gold `dim_patients`.
- **Sparse columns:** many claim diagnosis slots (5–8) empty; payer address fields 100% null in payers seed.
- **Active records:** `stop` / `end_date` null often means still active (conditions, medications, allergies).
- **Amounts** in claims/encounters stored as strings in CSV — cast to `double` in silver.

## Medallion mapping

| Layer | Implementation |
|-------|----------------|
| Bronze | `dbt seed` → `raw.raw_*` tables; `sources.bronze` |
| Silver | `stg_*` views + `int_*` enriched views |
| Gold | `dim_*`, `fct_*`, `mart_*` tables for analytics |
