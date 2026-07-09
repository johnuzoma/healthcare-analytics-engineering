SELECT
    DATE AS date_time,
    PATIENT AS patient_id,
    ENCOUNTER AS encounter_id,
    CODE AS code,
    DESCRIPTION AS description,
    BASE_COST AS base_cost
FROM {{ source('synthea_ehr', 'immunizations') }}