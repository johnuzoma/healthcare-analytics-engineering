SELECT
    Id AS id,
    START AS start_date,
    STOP AS end_date,
    PATIENT AS patient_id,
    ENCOUNTER AS encounter_id,
    CODE AS code,
    DESCRIPTION AS description,
    REASONCODE AS reason_code,
    REASONDESCRIPTION AS reason_description
FROM {{ source('synthea_ehr', 'careplans') }}