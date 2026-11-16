SELECT
    DATE AS obs_date_time,
    CAST(DATE AS DATE) AS obs_date,
    DATE_FORMAT(DATE, 'HH:mm:ss') AS obs_time,
    PATIENT AS patient_id,
    ENCOUNTER AS encounter_id,
    CAST(CODE AS STRING) AS code,
    DESCRIPTION AS obs_description,
    VALUE AS obs_value,
    UNITS AS units,
    TYPE AS obs_type
FROM {{ source('bronze', 'observations') }}