SELECT
    date_time,
    patient_id,
    encounter_id,
    description,
    value,
    units
FROM {{ ref('b_observations') }}