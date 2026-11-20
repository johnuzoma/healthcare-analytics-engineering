SELECT
    date AS obs_date_time,
    CAST(date AS DATE) AS obs_date,
    DATE_FORMAT(date, 'HH:mm:ss') AS obs_time,
    patient AS patient_id,
    encounter AS enc_id,
    INITCAP(
        REPLACE(category, '-', ' ')
    ) AS obs_category,
    code,
    description AS obs_description,
    value AS obs_value,
    units AS obs_unit,
    type AS obs_type
FROM {{ source('bronze', 'observations') }}
