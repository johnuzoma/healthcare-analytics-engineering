SELECT
    Id AS careplan_id,
    START AS cp_start_date,
    STOP AS cp_end_date,
    PATIENT AS patient_id,
    ENCOUNTER AS encounter_id,
    CAST(CODE AS STRING) AS code,
    DESCRIPTION AS cp_description,
    CAST(REASONCODE AS STRING) AS reason_code,
    REASONDESCRIPTION AS reason
FROM {{ source('bronze', 'careplans') }}