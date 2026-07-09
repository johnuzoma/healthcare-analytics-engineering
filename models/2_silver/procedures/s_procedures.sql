SELECT
    date_time,
    patient_id,
    encounter_id,
    description,
    base_cost,
    reason_description
FROM {{ ref('b_procedures') }}