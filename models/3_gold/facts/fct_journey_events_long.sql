WITH conditions AS (
    SELECT
        patient_id,
        enc_id,
        cond_start_date AS event_start_date,
        NULL AS event_start_time,
        cond_end_date AS event_end_date,
        NULL AS event_end_time,
        CONCAT(condition_type, ' Condition') AS event_type,
        condition_name AS event_description,
        NULL AS event_reason,
        NULL AS cost,
        9 AS event_sort
    FROM {{ ref('s_conditions') }}
),

encounters AS (
    SELECT
        patient_id,
        enc_id,
        enc_start_date AS event_start_date,
        enc_start_time AS event_start_time,
        enc_end_date AS event_end_date,
        enc_end_time AS event_end_time,
        encounter_class AS event_type,
        encounter_description AS event_description,
        encounter_reason AS event_reason,
        base_encounter_cost AS cost,
        CASE
            WHEN encounter_class = 'Wellness' THEN 1
            WHEN encounter_class = 'Outpatient' THEN 2
            WHEN encounter_class = 'Ambulatory' THEN 3
            WHEN encounter_class = 'Emergency' THEN 4
            WHEN encounter_class = 'Urgent Care' THEN 5
            WHEN encounter_class = 'Inpatient' THEN 6
        END AS event_sort
    FROM {{ ref('s_encounters') }}
),

careplans AS (
    SELECT
        patient_id,
        enc_id,
        cp_start_date AS event_start_date,
        NULL AS event_start_time,
        cp_end_date AS event_end_date,
        NULL AS event_end_time,
        'Careplan' AS event_type,
        cp_description AS event_description,
        cp_reason AS event_reason,
        NULL AS cost,
        14 AS event_sort
    FROM {{ ref('s_careplans') }}
),

procedures AS (
    SELECT
        patient_id,
        enc_id,
        pr_start_date AS event_start_date,
        pr_start_time AS event_start_time,
        pr_end_date AS event_end_date,
        pr_end_time AS event_end_time,
        'Procedure' AS event_type,
        pr_description AS event_description,
        pr_reason AS event_reason,
        pr_base_cost AS cost,
        11 AS event_sort
    FROM {{ ref('s_procedures') }}
),

imaging_studies AS (
    SELECT
        patient_id,
        enc_id,
        im_date AS event_start_date,
        im_time AS event_start_time,
        im_date AS event_end_date,
        im_time AS event_end_time,
        'Imaging Study' AS event_type,
        CONCAT(sop_description, ' > ', bodysite_description) AS event_description,
        NULL AS event_reason,
        NULL AS cost,
        10 AS event_sort
    FROM {{ ref('s_imaging_studies') }}
),

immunizations AS (
    SELECT
        patient_id,
        enc_id,
        imm_date AS event_start_date,
        imm_time AS event_start_time,
        imm_date AS event_end_date,
        imm_time AS event_end_time,
        'Immunization' AS event_type,
        imm_description AS event_description,
        NULL AS event_reason,
        imm_base_cost AS cost,
        12 AS event_sort
    FROM {{ ref('s_immunizations') }}
),

allergies AS (
    SELECT
        patient_id,
        enc_id,
        alg_start_date AS event_start_date,
        NULL AS event_start_time,
        alg_end_date AS event_end_date,
        NULL AS event_end_time,
        alg_type AS event_type,
        alg_description AS event_description,
        alg_category AS event_reason,
        NULL AS cost,
        7 AS event_sort
    FROM {{ ref('s_allergies') }}
),

observations AS (
    SELECT      
        patient_id,
        enc_id,
        obs_date AS event_start_date,
        obs_time AS event_start_time,
        obs_date AS event_end_date,
        obs_time AS event_end_time,
        'Observation' AS event_type,
        obs_description AS event_description,
        NULL AS event_reason,
        NULL AS cost,
        8 AS event_sort
    FROM {{ ref('s_observations') }}
),

medications AS (
    SELECT
        patient_id,
        enc_id,
        med_start_date AS event_start_date,
        med_start_time AS event_start_time,
        med_end_date AS event_end_date,
        med_end_time AS event_end_time,
        'Medication' AS event_type,
        med_description AS event_description,
        med_reason AS event_reason,
        med_total_cost AS cost,
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
    ej.jny_id,
    ej.jny_seq_no,
    u.*, 
    ej.provider_id,
    ej.organization_id,
    ej.payer_id,
    DATEDIFF(
        DAY, 
        LAG(u.event_start_date) OVER (PARTITION BY u.patient_id ORDER BY ej.jny_seq_no, u.event_start_date, u.event_sort, u.event_start_time),
        u.event_start_date
    ) AS days_since_previous_event,
    DATEDIFF(
        DAY, 
        MIN(event_start_date) OVER (PARTITION BY ej.jny_id ORDER BY event_start_date, event_sort, event_start_time), 
        event_start_date
    ) AS days_since_jny_start
FROM unioned AS u
LEFT JOIN {{ ref('s_encounter_journeys') }} AS ej
    ON u.enc_id = ej.enc_id

--where ej.jny_id = '01ccaf175f777a47f8feb631eacba56f'
--order by u.event_start_date
--WHERE u.patient_id = '0288c42c-43a1-9878-4a9d-6b96caa12c40' and ej.jny_seq_no is not null
--order by ej.jny_seq_no, u.event_start_date, u.event_sort