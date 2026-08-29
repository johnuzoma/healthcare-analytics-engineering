SELECT
    b_encounters.id,
    b_encounters.start_date_time,
    CAST(b_encounters.start_date_time AS DATE) AS start_date,
    DATE_FORMAT(start_date_time, 'HH:mm:ss') AS start_time,
    b_encounters.end_date_time,
    CAST(b_encounters.end_date_time AS DATE) AS end_date,
    DATE_FORMAT(b_encounters.end_date_time, 'HH:mm:ss') AS end_time,
    b_encounters.patient_id,
    DATEDIFF(DAY, b_encounters.start_date_time, b_encounters.end_date_time) AS length_of_stay,
    b_encounters.organization_id,
    b_encounters.provider_id,
    b_encounters.payer_id,
    INITCAP(b_encounters.encounter_class),
    b_encounters.description,
    b_encounters.base_encounter_cost,
    b_encounters.total_claim_cost,
    b_encounters.payer_coverage,
    b_encounters.reason_description,
    
    CASE
        WHEN b_careplans.encounter_id IS NOT NULL
        THEN 1
        ELSE 0
    END AS had_a_careplan,
    DATEDIFF(MONTH, b_careplans.start_date, b_careplans.end_date) AS careplan_duration_months,
    b_careplans.description AS careplan_description,
    b_careplans.reason_description AS careplan_reason,
    
    CASE
        WHEN b_devices.encounter_id IS NOT NULL
        THEN 1
        ELSE 0
    END AS used_a_device,
    DATEDIFF(MINUTE, b_devices.start_date_time, CAST(b_devices.end_date_time AS TIMESTAMP)) AS device_use_duration_mins,
    b_devices.description AS device_description,
    
    CASE
        WHEN b_conditions.encounter_id IS NOT NULL
        THEN 1
        ELSE 0
    END AS had_a_condition,
    YEAR(b_conditions.start_date) AS condition_onset_year,
    DATEDIFF(DAY, b_conditions.start_date, b_conditions.end_date) AS condition_duration_days,
    b_conditions.description AS condition_description,

    CASE
        WHEN b_allergies.encounter_id IS NOT NULL
        THEN 1
        ELSE 0
    END AS had_an_allergy,
    YEAR(b_allergies.start_date) AS allergy_onset_year,
    DATEDIFF(YEAR, b_allergies.start_date, b_allergies.end_date) AS allergy_duration_years,
    b_allergies.description AS allergy_description,

    CASE
        WHEN b_procedures.encounter_id IS NOT NULL
        THEN 1
        ELSE 0
    END AS had_a_procedure,
    b_procedures.description AS procedure_description,
    b_procedures.base_cost AS procedure_base_cost,
    b_procedures.reason_description AS procedure_reason

FROM {{ ref('b_encounters') }}

LEFT JOIN {{ ref('b_careplans') }}
    ON b_encounters.id = b_careplans.encounter_id
    AND b_encounters.patient_id = b_careplans.patient_id

LEFT JOIN {{ ref('b_devices') }}
    ON b_encounters.id = b_devices.encounter_id
    AND b_encounters.patient_id = b_devices.patient_id

LEFT JOIN {{ ref('b_conditions') }}
    ON b_encounters.id = b_conditions.encounter_id
    AND b_encounters.patient_id = b_conditions.patient_id

LEFT JOIN {{ ref('b_allergies') }}
    ON b_encounters.id = b_allergies.encounter_id
    AND b_encounters.patient_id = b_allergies.patient_id

LEFT JOIN {{ ref('b_procedures') }}
    ON b_encounters.id = b_procedures.encounter_id
    AND b_encounters.patient_id = b_procedures.patient_id