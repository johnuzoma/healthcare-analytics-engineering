SELECT
    start AS alg_start_date,
    stop AS alg_end_date,
    patient AS patient_id,
    encounter AS encounter_id,
    CAST(CODE AS STRING) AS code,
    description AS alg_description
FROM {{ source('bronze', 'allergies') }}