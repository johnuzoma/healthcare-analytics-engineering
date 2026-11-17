SELECT
    date AS obs_date_time,
    CAST(date AS DATE) AS obs_date,
    DATE_FORMAT(date, 'HH:mm:ss') AS obs_time,
    patient AS patient_id,
    encounter AS encounter_id,
    INITCAP(
        REPLACE(category, '-', ' ')
    ) AS category,
    code,
    description AS obs_description,
    value AS obs_value,
    units AS units,
    type AS obs_type
FROM {{ source('bronze', 'observations') }}
