SELECT
    START AS start_date_time,
    CAST(START AS DATE) AS dv_start_date,
    DATE_FORMAT(START, 'HH:mm:ss') AS dv_start_time,
    STOP AS end_date_time,
    CAST(STOP AS DATE) AS dv_end_date,
    DATE_FORMAT(STOP, 'HH:mm:ss') AS dv_end_time,
    PATIENT AS patient_id,
    ENCOUNTER AS encounter_id,
    CAST(CODE AS STRING) AS code,
    DESCRIPTION AS dv_description,
    UDI AS unique_device_identifier
FROM {{ source('bronze', 'devices') }}