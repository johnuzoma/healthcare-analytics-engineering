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
),

admissions_within_10d AS (
    SELECT
        non_ip_encounters.Id AS non_ip_encounter_id,
        ip_encounters.DESCRIPTION AS admitted_within_10d_description,
        ip_encounters.REASONDESCRIPTION AS admitted_within_10d_reason,
        CAST(ip_encounters.START AS DATE) AS admitted_within_10d_start_date,
        DATE_FORMAT(ip_encounters.START, 'HH:mm:ss') AS admitted_within_10d_start_time,
        ROW_NUMBER() OVER (PARTITION BY non_ip_encounters.Id ORDER BY ip_encounters.START) AS row_num
    FROM {{ source('bronze', 'encounters') }} AS non_ip_encounters
    INNER JOIN {{ source('bronze', 'encounters') }} AS ip_encounters
        ON non_ip_encounters.PATIENT = ip_encounters.PATIENT
        AND ip_encounters.ENCOUNTERCLASS = 'inpatient'
        AND non_ip_encounters.ENCOUNTERCLASS <> 'inpatient'
        AND ip_encounters.Id <> non_ip_encounters.Id
        AND ip_encounters.START BETWEEN non_ip_encounters.START AND DATEADD(DAY, 10, non_ip_encounters.START)
)

SELECT
    -- encounter overview
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
    {{ capitalize_value("
        REPLACE(encounters.ENCOUNTERCLASS, 'urgentcare', ('urgent care'))
    ") }} AS encounter_class,
    encounters.BASE_ENCOUNTER_COST AS base_encounter_cost,
    encounters.TOTAL_CLAIM_COST AS total_claim_cost,
    encounters.PAYER_COVERAGE AS payer_coverage,
    {{ remove_unnecessary_whitespace("
        COALESCE(
            encounters.REASONDESCRIPTION,
            encounters.DESCRIPTION,
            'Not Given'
        )
    ") }} AS encounter_reason,
    
    -- allergies
    CASE
        WHEN allergies.ENCOUNTER IS NOT NULL
        THEN 1
        ELSE 0
    END AS had_an_allergy,
    allergies.number_of_allergies,

    -- careplans
    CASE
        WHEN careplans.ENCOUNTER IS NOT NULL
        THEN 1
        ELSE 0
    END AS had_a_careplan,
    careplans.number_of_careplans,

    -- conditions
    CASE
        WHEN conditions.ENCOUNTER IS NOT NULL
        THEN 1
        ELSE 0
    END AS had_a_condition,
    conditions.number_of_conditions,

    -- devices
    CASE
        WHEN devices.ENCOUNTER IS NOT NULL
        THEN 1
        ELSE 0
    END AS used_a_device,
    {{ remove_unnecessary_whitespace("
        REPLACE(
            devices.DESCRIPTION, 
            ' (physical object)', ''
        )
    ") }} AS device_name,

    -- immunizations
    CASE
        WHEN immunizations.ENCOUNTER IS NOT NULL
        THEN 1
        ELSE 0
    END AS had_an_immunization,
    immunizations.number_of_immunizations,
    immunizations.total_cost_of_immunizations,

    -- procedures
    CASE
        WHEN procedures.ENCOUNTER IS NOT NULL
        THEN 1
        ELSE 0
    END AS had_a_procedure,
    procedures.number_of_procedures,
    procedures.total_cost_of_procedures,

    -- admissions within 10 days
    CASE
        WHEN encounters.ENCOUNTERCLASS = 'inpatient' THEN NULL
        WHEN adm.non_ip_encounter_id IS NOT NULL THEN 1
        ELSE 0
    END AS admitted_within_10d,
    {{ remove_unnecessary_whitespace("
        COALESCE(
            adm.admitted_within_10d_reason, 
            adm.admitted_within_10d_description
        )
    ") }} AS admitted_within_10d_reason,
    adm.admitted_within_10d_start_date,
    adm.admitted_within_10d_start_time,

    -- billing types
    CASE
        WHEN encounters.PAYER IS NOT NULL 
            AND encounters.PAYER <> 'b1c428d6-4f07-31e0-90f0-68ffa6ff8c76' -- id for "NO INSURANCE"
            AND procedures.ENCOUNTER IS NOT NULL
            THEN 'FPP'
        ELSE 'Per Diem'
    END AS encounter_billing_type

FROM {{ source('bronze', 'encounters') }} AS encounters

LEFT JOIN allergies
    ON encounters.Id = allergies.ENCOUNTER
    AND encounters.PATIENT = allergies.PATIENT

LEFT JOIN careplans
    ON encounters.Id = careplans.ENCOUNTER
    AND encounters.PATIENT = careplans.PATIENT

LEFT JOIN conditions
    ON encounters.Id = conditions.ENCOUNTER
    AND encounters.PATIENT = conditions.PATIENT

LEFT JOIN {{ source('bronze', 'devices') }} AS devices
    ON encounters.Id = devices.ENCOUNTER
    AND encounters.PATIENT = devices.PATIENT

LEFT JOIN immunizations
    ON encounters.Id = immunizations.ENCOUNTER
    AND encounters.PATIENT = immunizations.PATIENT

LEFT JOIN procedures
    ON encounters.Id = procedures.ENCOUNTER
    AND encounters.PATIENT = procedures.PATIENT

LEFT JOIN admissions_within_10d AS adm
    ON encounters.Id = adm.non_ip_encounter_id
    AND adm.row_num = 1