SELECT
    DATE AS imm_date_time,
    CAST(DATE AS DATE) AS imm_date,
    DATE_FORMAT(DATE, 'HH:mm:ss') AS imm_time,
    PATIENT AS patient_id,
    ENCOUNTER AS encounter_id,
    CAST(CODE AS STRING) AS code,
    DESCRIPTION AS imm_description,
    BASE_COST AS base_cost
FROM {{ source('bronze', 'immunizations') }}