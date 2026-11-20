SELECT
    id AS careplan_id,
    start AS cp_start_date,
    stop AS cp_end_date,
    patient AS patient_id,
    encounter AS enc_id,
    CAST(code AS STRING) AS code,
    description AS cp_description,
    CAST(reasoncode AS STRING) AS reason_code,
    reasondescription AS cp_reason
FROM {{ source('bronze', 'careplans') }}