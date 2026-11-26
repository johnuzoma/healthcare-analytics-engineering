WITH conditions AS (
    SELECT
        patient_id,
        enc_id,
        cond_start_date AS event_start_date,
        NULL AS event_start_time,
        cond_end_date AS event_end_date,
        NULL AS event_end_time,
        CASE
            WHEN condition_type IN ('Situation', 'Finding') THEN condition_type
            ELSE CONCAT(condition_type, ' Condition')
        END AS event_type,
        condition_name AS event_description,
        NULL AS event_reason,
        NULL AS cost,
        9 AS event_sort
    FROM {{ ref('s_conditions') }}
),

encounter_jnys AS (
    SELECT
        jny_id,
        jny_seq_no,
        patient_id,
        enc_id,
        enc_start_date AS event_start_date,
        enc_start_time AS event_start_time,
        enc_end_date AS event_end_date,
        enc_end_time AS event_end_time,
        enc_class AS event_type,
        enc_description AS event_description,
        enc_reason AS event_reason,
        base_enc_cost AS cost,
        CASE
            WHEN enc_class = 'Wellness' THEN 1
            WHEN enc_class = 'Outpatient' THEN 2
            WHEN enc_class = 'Ambulatory' THEN 3
            WHEN enc_class = 'Emergency' THEN 4
            WHEN enc_class = 'Urgent Care' THEN 5
            WHEN enc_class = 'Inpatient' THEN 6
        END AS event_sort,
        provider_id,
        organization_id,
        payer_id,
        is_admission_within_10d
    FROM {{ ref('s_encounter_journeys') }}
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
),

journeyed AS (
    SELECT
        ej.jny_id,
        ej.jny_seq_no,
        u.*, 
        ej.provider_id,
        ej.organization_id,
        ej.payer_id,
        'NA' AS is_admission_within_10d,
        0 AS is_encounter
    FROM unioned AS u
    INNER JOIN encounter_jnys AS ej
        ON u.enc_id = ej.enc_id
)

SELECT *, 1 AS is_encounter FROM encounter_jnys
UNION ALL
SELECT * FROM journeyed