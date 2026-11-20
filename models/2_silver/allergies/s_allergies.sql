SELECT
    start AS alg_start_date,
    stop AS alg_end_date,
    patient AS patient_id,
    encounter AS enc_id,
    CAST(CODE AS STRING) AS code,
     {{ capitalize_value("
        CONCAT(category, ' ', type)
    ") }} AS alg_type,
    description AS alg_description,
    {{ capitalize_value("
        (CONCAT(severity1, ' ', description1))
    ") }} AS first_alg_reaction,
    {{ capitalize_value("
        (CONCAT(severity2, ' ', description2))
    ") }} AS second_alg_reaction
FROM {{ source('bronze', 'allergies') }}