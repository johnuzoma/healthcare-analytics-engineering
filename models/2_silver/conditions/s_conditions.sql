SELECT
    start AS cond_start_date,
    stop AS cond_end_date,
    patient AS patient_id,
    encounter AS encounter_id,
    CAST(code AS STRING) AS condition_code,
    description AS condition_name,
    CASE
        WHEN stop IS NULL THEN 'Chronic'
        ELSE 'Acute'
    END AS condition_type
FROM {{ source('bronze', 'conditions') }}