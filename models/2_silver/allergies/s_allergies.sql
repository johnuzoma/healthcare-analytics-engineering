SELECT
    START AS alg_start_date,
    STOP AS alg_end_date,
    PATIENT AS patient_id,
    ENCOUNTER AS encounter_id,
    CAST(CODE AS STRING) AS code,
    DESCRIPTION AS alg_description
FROM {{ source('bronze', 'allergies') }}