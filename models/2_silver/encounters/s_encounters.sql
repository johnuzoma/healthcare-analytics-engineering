SELECT
    encounters.Id AS visit_id,
    CAST(encounters.START AS DATE) AS visit_start_date,
    DATE_FORMAT(encounters.START, 'HH:mm:ss') AS visit_start_time,
    CAST(encounters.STOP AS DATE) AS visit_end_date,
    DATE_FORMAT(encounters.STOP, 'HH:mm:ss') AS visit_end_time,
    encounters.PATIENT AS patient_Id,
    DATEDIFF(DAY, encounters.START, encounters.STOP) AS length_of_stay,
    encounters.ORGANIZATION AS organization_id,
    encounters.PROVIDER AS provider_id,
    encounters.PAYER AS payer_id,
    INITCAP(encounters.ENCOUNTERCLASS) AS encounter_class,
    encounters.DESCRIPTION AS description,
    encounters.BASE_ENCOUNTER_COST AS base_encounter_cost,
    encounters.TOTAL_CLAIM_COST AS total_claim_cost,
    encounters.PAYER_COVERAGE AS payer_coverage,
    encounters.REASONDESCRIPTION AS reason,
    
    CASE
        WHEN careplans.ENCOUNTER IS NOT NULL
        THEN 1
        ELSE 0
    END AS had_a_careplan,
    DATEDIFF(MONTH, careplans.START, careplans.STOP) AS careplan_duration_months,
    careplans.DESCRIPTION AS careplan_description,
    careplans.REASONDESCRIPTION AS careplan_reason,
    
    CASE
        WHEN devices.ENCOUNTER IS NOT NULL
        THEN 1
        ELSE 0
    END AS used_a_device,
    DATEDIFF(MINUTE, devices.START, CAST(devices.STOP AS TIMESTAMP)) AS device_use_duration_mins,
    devices.DESCRIPTION AS device_description,
    
    CASE
        WHEN conditions.ENCOUNTER IS NOT NULL
        THEN 1
        ELSE 0
    END AS had_a_condition,
    YEAR(conditions.START) AS condition_onset_year,
    DATEDIFF(DAY, conditions.START, conditions.STOP) AS condition_duration_days,
    conditions.DESCRIPTION AS condition_description,

    CASE
        WHEN allergies.ENCOUNTER IS NOT NULL
        THEN 1
        ELSE 0
    END AS had_an_allergy,
    YEAR(allergies.START) AS allergy_onset_year,
    DATEDIFF(YEAR, allergies.START, allergies.STOP) AS allergy_duration_years,
    allergies.DESCRIPTION AS allergy_description,

    CASE
        WHEN procedures.ENCOUNTER IS NOT NULL
        THEN 1
        ELSE 0
    END AS had_a_procedure,
    procedures.DATE AS procedure_date_time,
    procedures.DESCRIPTION AS procedure_description,
    procedures.BASE_COST AS procedure_base_cost,
    procedures.REASONDESCRIPTION AS procedure_reason

FROM {{ source('bronze', 'encounters') }}

LEFT JOIN {{ source('bronze', 'careplans') }}
    ON encounters.Id = careplans.ENCOUNTER
    AND encounters.PATIENT = careplans.PATIENT

LEFT JOIN {{ source('bronze', 'devices') }}
    ON encounters.Id = devices.ENCOUNTER
    AND encounters.PATIENT = devices.PATIENT

LEFT JOIN {{ source('bronze', 'conditions') }}
    ON encounters.Id = conditions.ENCOUNTER
    AND encounters.PATIENT = conditions.PATIENT

LEFT JOIN {{ source('bronze', 'allergies') }}
    ON encounters.Id = allergies.ENCOUNTER
    AND encounters.PATIENT = allergies.PATIENT

LEFT JOIN {{ source('bronze', 'procedures') }}
    ON encounters.Id = procedures.ENCOUNTER
    AND encounters.PATIENT = procedures.PATIENT