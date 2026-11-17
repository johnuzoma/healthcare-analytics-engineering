SELECT
    start AS start_date_time,
    CAST(start AS DATE) AS dv_start_date,
    DATE_FORMAT(start, 'HH:mm:ss') AS dv_start_time,
    stop AS end_date_time,
    CAST(stop AS DATE) AS dv_end_date,
    DATE_FORMAT(stop, 'HH:mm:ss') AS dv_end_time,
    patient AS patient_id,
    encounter AS encounter_id,
    CAST(code AS STRING) AS code,
    description AS dv_description,
    udi AS unique_device_identifier
FROM {{ source('bronze', 'devices') }}