SELECT
    id,
    is_alive,
    age,
    age_band,
    years_since_death,
    marital_status,
    race,
    ethnicity,
    gender,
    patient_state
FROM {{ ref('s_patients') }}