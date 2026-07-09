SELECT
    START AS start_date_time,
    STOP AS end_date_time,
    PATIENT AS patient_id,
    ENCOUNTER AS encounter_id,
    CODE AS code,
    DESCRIPTION AS description,
    UDI AS udi
FROM {{ source('synthea_ehr', 'devices') }}