WITH allergies AS (
    SELECT
        encounter,
        patient,
        COUNT(*) AS number_of_allergies
    FROM {{ source('bronze', 'allergies') }}
    GROUP BY encounter, patient
),

careplans AS (
    SELECT
        encounter,
        patient,
        COUNT(*) AS number_of_careplans
    FROM {{ source('bronze', 'careplans') }}
    GROUP BY encounter, patient
),

conditions AS (
    SELECT
        encounter,
        patient,
        COUNT(*) AS number_of_conditions
    FROM {{ source('bronze', 'conditions') }}
    GROUP BY encounter, patient
),

immunizations AS (
    SELECT
        encounter,
        patient,
        COUNT(*) AS number_of_immunizations,
        SUM(base_cost) AS total_cost_of_immunizations
    FROM {{ source('bronze', 'immunizations') }}
    GROUP BY encounter, patient
),

procedures AS (
    SELECT
        encounter,
        patient,
        COUNT(*) AS number_of_procedures,
        SUM(base_cost) AS total_cost_of_procedures
    FROM {{ source('bronze', 'procedures') }}
    GROUP BY encounter, patient
),

admissions_within_10d AS (
    SELECT
        non_ip_encounters.id AS non_ip_encounter_id,
        ip_encounters.description AS admitted_within_10d_description,
        ip_encounters.reasondescription AS admitted_within_10d_reason,
        CAST(ip_encounters.start AS DATE) AS admitted_within_10d_start_date,
        DATE_FORMAT(ip_encounters.start, 'HH:mm:ss') AS admitted_within_10d_start_time,
        ROW_NUMBER() OVER (
            PARTITION BY non_ip_encounters.id
            ORDER BY ip_encounters.start
        ) AS row_num
    FROM {{ source('bronze', 'encounters') }} AS non_ip_encounters
    INNER JOIN {{ source('bronze', 'encounters') }} AS ip_encounters
        ON non_ip_encounters.patient = ip_encounters.patient
        AND ip_encounters.encounterclass = 'inpatient'
        AND non_ip_encounters.encounterclass <> 'inpatient'
        AND ip_encounters.id <> non_ip_encounters.id
        AND ip_encounters.start BETWEEN non_ip_encounters.start
            AND DATEADD(DAY, 10, non_ip_encounters.start)
)

SELECT
    -- encounter overview
    encounters.id AS encounter_id,
    encounters.start AS enc_start_date_time,
    CAST(encounters.start AS DATE) AS enc_start_date,
    DATE_FORMAT(encounters.start, 'HH:mm:ss') AS enc_start_time,
    encounters.stop AS enc_end_date_time,
    CAST(encounters.stop AS DATE) AS enc_end_date,
    DATE_FORMAT(encounters.stop, 'HH:mm:ss') AS enc_end_time,
    encounters.patient AS patient_id,
    DATEDIFF(
        MINUTE,
        encounters.start,
        COALESCE(encounters.stop, CURRENT_DATE())
    ) AS length_of_stay_mins,
    DATEDIFF(
        DAY,
        encounters.start,
        COALESCE(encounters.stop, CURRENT_DATE())
    ) AS length_of_stay_days,
    encounters.organization AS organization_id,
    encounters.provider AS provider_id,
    encounters.payer AS payer_id,
    {{ capitalize_value("
        REPLACE(encounters.encounterclass, 'urgentcare', 'urgent care')
    ") }} AS encounter_class,
    encounters.base_encounter_cost,
    encounters.total_claim_cost,
    encounters.payer_coverage,
    CAST(encounters.code AS STRING) AS code,
    encounters.description AS encounter_description,
    CAST(encounters.reasoncode AS STRING) AS reason_code,
    {{ remove_unnecessary_whitespace("
        COALESCE(
            encounters.reasondescription,
            encounters.description,
            'Not Given'
        )
    ") }} AS encounter_reason,

    -- allergies
    CASE
        WHEN allergies.encounter IS NOT NULL THEN 1
        ELSE 0
    END AS had_an_allergy,
    allergies.number_of_allergies,

    -- careplans
    CASE
        WHEN careplans.encounter IS NOT NULL THEN 1
        ELSE 0
    END AS had_a_careplan,
    careplans.number_of_careplans,

    -- conditions
    CASE
        WHEN conditions.encounter IS NOT NULL THEN 1
        ELSE 0
    END AS had_a_condition,
    conditions.number_of_conditions,

    -- immunizations
    CASE
        WHEN immunizations.encounter IS NOT NULL THEN 1
        ELSE 0
    END AS had_an_immunization,
    immunizations.number_of_immunizations,
    immunizations.total_cost_of_immunizations,

    -- procedures
    CASE
        WHEN procedures.encounter IS NOT NULL THEN 1
        ELSE 0
    END AS had_a_procedure,
    procedures.number_of_procedures,
    procedures.total_cost_of_procedures,

    -- admissions within 10 days
    CASE
        WHEN encounters.encounterclass = 'inpatient' THEN 'NA'
        WHEN adm.non_ip_encounter_id IS NOT NULL THEN '1'
        ELSE '0'
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
        WHEN encounters.payer IS NOT NULL
            AND encounters.payer <> 'b1c428d6-4f07-31e0-90f0-68ffa6ff8c76'
            AND procedures.encounter IS NOT NULL
            THEN 'FPP'
        ELSE 'Per Diem'
    END AS encounter_billing_type

FROM {{ source('bronze', 'encounters') }} AS encounters

LEFT JOIN allergies
    ON encounters.id = allergies.encounter
    AND encounters.patient = allergies.patient

LEFT JOIN careplans
    ON encounters.id = careplans.encounter
    AND encounters.patient = careplans.patient

LEFT JOIN conditions
    ON encounters.id = conditions.encounter
    AND encounters.patient = conditions.patient

LEFT JOIN immunizations
    ON encounters.id = immunizations.encounter
    AND encounters.patient = immunizations.patient

LEFT JOIN procedures
    ON encounters.id = procedures.encounter
    AND encounters.patient = procedures.patient

LEFT JOIN admissions_within_10d AS adm
    ON encounters.id = adm.non_ip_encounter_id
    AND adm.row_num = 1