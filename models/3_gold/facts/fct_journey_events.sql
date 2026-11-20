WITH conditions AS (
    SELECT
        --journey_seq_no,
        patient_id,
        encounter_id,
        cond_start_date AS event_date,
        NULL AS event_time,
        CONCAT(condition_type, ' Condition') AS event_type,
        condition_name AS event_name,
        NULL AS cost,
        9 AS event_sort
    FROM {{ ref('s_conditions') }}
),

encounters AS (
    SELECT
        --journey_seq_no,
        patient_id,
        encounter_id,
        enc_start_date AS event_date,
        enc_start_time AS event_time,
        encounter_class AS event_type,
        encounter_description AS event_name,
        base_encounter_cost AS cost,
        CASE
            WHEN encounter_class = 'Wellness' THEN 1
            WHEN encounter_class = 'Outpatient' THEN 2
            WHEN encounter_class = 'Ambulatory' THEN 3
            WHEN encounter_class = 'Emergency' THEN 4
            WHEN encounter_class = 'Urgent Care' THEN 4
            WHEN encounter_class = 'Inpatient' THEN 4
        END AS event_sort
    FROM {{ ref('s_encounters') }}
),

careplans AS (
    SELECT
        patient_id,
        encounter_id,
        cp_start_date AS event_date,
        NULL AS event_time,
        'Careplan' AS event_type,
        cp_description AS event_name,
        NULL AS cost,
        14 AS event_sort
    FROM {{ ref('s_careplans') }}
),

procedures AS (
    SELECT
        patient_id,
        encounter_id,
        pr_start_date AS event_date,
        pr_start_time AS event_time,
        'Procedure' AS event_type,
        pr_description AS event_name,
        base_cost AS cost,
        11 AS event_sort
    FROM {{ ref('s_procedures') }}
),

imaging_studies AS (
    SELECT
        patient_id,
        encounter_id,
        im_date AS event_date,
        im_time AS event_time,
        'Imaging Study' AS event_type,
        modality_description AS event_name,
        NULL AS cost,
        10 AS event_sort
    FROM {{ ref('s_imaging_studies') }}
),

immunizations AS (
    SELECT
        patient_id,
        encounter_id,
        imm_date AS event_date,
        imm_time AS event_time,
        'Immunization' AS event_type,
        imm_description AS event_name,
        base_cost,
        12 AS event_sort
    FROM {{ ref('s_immunizations') }}
),

allergies AS (
    SELECT
        patient_id,
        encounter_id,
        alg_start_date AS event_date,
        NULL AS event_time,
        alg_type AS event_type,
        alg_description AS event_name,
        NULL AS cost,
        7 AS event_sort
    FROM {{ ref('s_allergies') }}
),

observations AS (
    SELECT      
        patient_id,
        encounter_id,
        obs_date AS event_date,
        obs_time AS event_time,
        'Observation' AS event_type,
        obs_description AS event_name,
        NULL AS cost,
        8 AS event_sort
    FROM {{ ref('s_observations') }}
),

medications AS (
    SELECT
        patient_id,
        encounter_id,
        med_start_date AS event_date,
        med_start_time AS event_time,
        'Medication' AS event_type,
        med_description AS event_name,
        total_cost AS cost,
        13 AS event_sort
    FROM {{ ref('s_medications') }}
),

unioned AS (
    SELECT * FROM encounters
    UNION ALL
    SELECT * FROM allergies
    UNION ALL
    SELECT * FROM observations
    UNION ALL
    SELECT * FROM conditions
    UNION ALL
    SELECT * FROM imaging_studies
    UNION ALL
    SELECT * FROM procedures
    UNION ALL
    SELECT * FROM immunizations
    UNION ALL
    SELECT * FROM medications
    UNION ALL
    SELECT * FROM careplans
)

SELECT
    ej.journey_seq_no,
    u.*, 
    ej.provider_id,
    DATEDIFF(
        DAY, 
        LAG(u.event_date) OVER (PARTITION BY u.patient_id ORDER BY ej.journey_seq_no, u.event_date, u.event_sort, u.event_time),
        u.event_date
    ) AS days_since_previous_event
FROM unioned AS u
LEFT JOIN {{ ref('s_encounter_journeys') }} AS ej
    ON u.encounter_id = ej.encounter_id