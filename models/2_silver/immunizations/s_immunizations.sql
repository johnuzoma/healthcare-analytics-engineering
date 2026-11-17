SELECT
    date AS imm_date_time,
    CAST(date AS DATE) AS imm_date,
    DATE_FORMAT(date, 'HH:mm:ss') AS imm_time,
    patient AS patient_id,
    encounter AS encounter_id,
    CAST(code AS STRING) AS code,
    description AS imm_description,
    base_cost AS base_cost
FROM {{ source('bronze', 'immunizations') }}