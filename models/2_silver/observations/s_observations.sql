SELECT
    DATE AS date_time,
    PATIENT AS patient_id,
    ENCOUNTER AS encounter_id,
    CODE AS code,
    DESCRIPTION AS obs_description,
    VALUE AS obs_value,
    UNITS AS units,
    TYPE AS obs_type
FROM {{ source('bronze', 'observations') }}