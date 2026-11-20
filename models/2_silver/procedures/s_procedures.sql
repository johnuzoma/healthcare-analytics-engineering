SELECT
    start AS pr_start_ts,
    CAST(start AS DATE) AS pr_start_date,
    DATE_FORMAT(start, 'HH:mm:ss') AS pr_start_time,
    stop AS pr_end_ts,
    CAST(stop AS DATE) AS pr_end_date,
    DATE_FORMAT(stop, 'HH:mm:ss') AS pr_end_time,
    patient AS patient_id,
    encounter AS enc_id,
    CAST(code AS STRING) AS code,
    description AS pr_description,
    base_cost AS pr_base_cost,
    CAST(reasoncode AS STRING) AS reason_code,
    reasondescription AS pr_reason
FROM {{ source('bronze', 'procedures') }}