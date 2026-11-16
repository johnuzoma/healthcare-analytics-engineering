SELECT
    START AS cond_start_date,
    STOP AS cond_end_date,
    PATIENT AS patient_id,
    ENCOUNTER AS encounter_id,
    CAST(CODE AS STRING) AS condition_code,
    DESCRIPTION AS condition_name,
    CASE
        WHEN STOP IS NULL THEN 'Chronic'
        ELSE 'Acute'
    END AS condition_type
FROM {{ source('bronze', 'conditions') }}