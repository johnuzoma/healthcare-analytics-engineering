SELECT
    id AS careplan_id,
    start AS cp_start_date,
    stop AS cp_end_date,
    patient AS patient_id,
    encounter AS encounter_id,
    CAST(code AS STRING) AS code,
    description AS cp_description,
    CAST(reasoncode AS STRING) AS reason_code,
    reasondescription AS reason
FROM {{ source('bronze', 'careplans') }}