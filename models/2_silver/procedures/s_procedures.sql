SELECT
    DATE AS pr_date_time,
    CAST(DATE AS DATE) AS pr_date,
    DATE_FORMAT(DATE, 'HH:mm:ss') AS pr_time,
    PATIENT AS patient_id,
    ENCOUNTER AS encounter_id,
    CAST(CODE AS STRING) AS code,
    DESCRIPTION AS pr_description,
    BASE_COST AS base_cost,
    CAST(REASONCODE AS STRING) AS reason_code,
    REASONDESCRIPTION AS reason
FROM {{ source('bronze', 'procedures') }}