SELECT
    Id AS id,
    START AS start_date_time,
    STOP AS end_date_time,
    PATIENT AS patient_id,
    ORGANIZATION AS organization_id,
    PROVIDER AS provider_id,
    PAYER AS payer_id,
    ENCOUNTERCLASS AS encounter_class,
    CODE AS code,
    DESCRIPTION AS description,
    BASE_ENCOUNTER_COST AS base_encounter_cost,
    TOTAL_CLAIM_COST AS total_claim_cost,
    PAYER_COVERAGE AS payer_coverage,
    REASONCODE AS reason_code,
    REASONDESCRIPTION AS reason_description
FROM {{ source('synthea_ehr', 'encounters') }}