SELECT
    PATIENT AS patient_id,
    START_YEAR AS start_year,
    END_YEAR AS end_year,
    PAYER AS payer_id,
    OWNERSHIP AS ownership
FROM {{ source('synthea_ehr', 'payer_transitions') }}