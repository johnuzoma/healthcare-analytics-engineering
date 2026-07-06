SELECT
    date_time,
    patient_id,
    encounter_id,
    description,
    base_cost
FROM {{ ref('b_immunizations') }}