WITH allergies AS (
    SELECT
        ENCOUNTER,
        PATIENT,
        COUNT(*) AS number_of_allergies
    FROM {{ source('bronze', 'allergies') }}
    GROUP BY ENCOUNTER, PATIENT
),

careplans AS (
    SELECT
        ENCOUNTER,
        PATIENT,
        COUNT(*) AS number_of_careplans
    FROM {{ source('bronze', 'careplans') }}
    GROUP BY ENCOUNTER, PATIENT
),

conditions AS (
    SELECT
        ENCOUNTER,
        PATIENT,
        COUNT(*) AS number_of_conditions
    FROM {{ source('bronze', 'conditions') }}
    GROUP BY ENCOUNTER, PATIENT
),

immunizations AS (
    SELECT
        ENCOUNTER,
        PATIENT,
        COUNT(*) AS number_of_immunizations,
        SUM(BASE_COST) AS total_cost_of_immunizations
    FROM {{ source('bronze', 'immunizations') }}
    GROUP BY ENCOUNTER, PATIENT
),

procedures AS (
    SELECT
        ENCOUNTER,
        PATIENT,
        COUNT(*) AS number_of_procedures,
        SUM(BASE_COST) AS total_cost_of_procedures
    FROM {{ source('bronze', 'procedures') }}
    GROUP BY ENCOUNTER, PATIENT
)

SELECT
    encounters.Id AS encounter_id,
    CAST(encounters.START AS DATE) AS encounter_start_date,
    DATE_FORMAT(encounters.START, 'HH:mm:ss') AS encounter_start_time,
    CAST(encounters.STOP AS DATE) AS encounter_end_date,
    DATE_FORMAT(encounters.STOP, 'HH:mm:ss') AS encounter_end_time,
    encounters.PATIENT AS patient_Id,
    DATEDIFF(MINUTE, encounters.START, COALESCE(encounters.STOP, CURRENT_DATE())) AS length_of_stay_mins,
    DATEDIFF(DAY, encounters.START, COALESCE(encounters.STOP, CURRENT_DATE())) AS length_of_stay_days,
    encounters.ORGANIZATION AS organization_id,
    encounters.PROVIDER AS provider_id,
    encounters.PAYER AS payer_id,
    INITCAP(encounters.ENCOUNTERCLASS) AS encounter_class,
    {{ remove_unnecessary_whitespace("encounters.DESCRIPTION") }} AS encounter_description,
    encounters.BASE_ENCOUNTER_COST AS base_encounter_cost,
    encounters.TOTAL_CLAIM_COST AS total_claim_cost,
    encounters.PAYER_COVERAGE AS payer_coverage,
    {{ remove_unnecessary_whitespace("encounters.REASONDESCRIPTION") }} AS reason,
    
    CASE
        WHEN allergies.ENCOUNTER IS NOT NULL
        THEN 1
        ELSE 0
    END AS had_an_allergy,
    allergies.number_of_allergies,

    CASE
        WHEN careplans.ENCOUNTER IS NOT NULL
        THEN 1
        ELSE 0
    END AS had_a_careplan,
    careplans.number_of_careplans,

    CASE
        WHEN conditions.ENCOUNTER IS NOT NULL
        THEN 1
        ELSE 0
    END AS had_a_condition,
    conditions.number_of_conditions,

    CASE
        WHEN devices.ENCOUNTER IS NOT NULL
        THEN 1
        ELSE 0
    END AS used_a_device,
    {{ remove_unnecessary_whitespace("REPLACE(devices.DESCRIPTION, ' (physical object)', '')") }} AS device_name,

    CASE
        WHEN immunizations.ENCOUNTER IS NOT NULL
        THEN 1
        ELSE 0
    END AS had_an_immunization,
    immunizations.number_of_immunizations,
    immunizations.total_cost_of_immunizations,

    CASE
        WHEN procedures.ENCOUNTER IS NOT NULL
        THEN 1
        ELSE 0
    END AS had_a_procedure,
    procedures.number_of_procedures,
    procedures.total_cost_of_procedures

FROM {{ source('bronze', 'encounters') }}

LEFT JOIN allergies
    ON encounters.Id = allergies.ENCOUNTER
    AND encounters.PATIENT = allergies.PATIENT

LEFT JOIN careplans
    ON encounters.Id = careplans.ENCOUNTER
    AND encounters.PATIENT = careplans.PATIENT

LEFT JOIN conditions
    ON encounters.Id = conditions.ENCOUNTER
    AND encounters.PATIENT = conditions.PATIENT

LEFT JOIN {{ source('bronze', 'devices') }}
    ON encounters.Id = devices.ENCOUNTER
    AND encounters.PATIENT = devices.PATIENT

LEFT JOIN immunizations
    ON encounters.Id = immunizations.ENCOUNTER
    AND encounters.PATIENT = immunizations.PATIENT

LEFT JOIN procedures
    ON encounters.Id = procedures.ENCOUNTER
    AND encounters.PATIENT = procedures.PATIENT