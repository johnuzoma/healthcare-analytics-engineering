SELECT
    start AS alg_start_date,
    stop AS alg_end_date,
    patient AS patient_id,
    encounter AS encounter_id,
    CAST(CODE AS STRING) AS code,
    CONCAT(description, ', ', description1, ', ', description2) AS alg_description,
    {{ capitalize_value("
        CONCAT(category, ' ', type)
    ") }} AS alg_type
FROM {{ source('bronze', 'allergies') }}