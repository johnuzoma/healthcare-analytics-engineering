SELECT
    DATE AS date_time,
    PATIENT AS patient_id,
    ENCOUNTER AS encounter_id,
    CODE AS code,
    DESCRIPTION AS description,
    VALUE AS value,
    UNITS AS units,
    TYPE AS type
FROM {{ source('synthea_ehr', 'observations') }}