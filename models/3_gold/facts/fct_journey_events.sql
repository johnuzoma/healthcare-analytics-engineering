WITH journeyed AS (
    SELECT * FROM {{ ref('s_encounter_journeys') }}
),

conditions AS (
    SELECT
        journey_seq_no,
        patient_id,
        encounter_id,
        cond_start_date AS event_date,
        NULL AS event_time,
        'Condition' AS event_type,
        condition_name AS event_name
    FROM journeyed
    WHERE condition_code IS NOT NULL
),

encounters AS (
    SELECT
        journey_seq_no,
        patient_id,
        encounter_id,
        enc_start_date AS event_date,
        enc_start_time AS event_time,
        encounter_class AS event_type,
        encounter_description AS event_name
    FROM journeyed
),

careplans AS (
    SELECT
        patient_id,
        encounter_id,
        cp_start_date AS event_date,
        NULL AS event_time,
        'Careplan' AS event_type,
        cp_description AS event_name
    FROM {{ ref('s_careplans') }}
),

procedures AS (
    SELECT
        patient_id,
        encounter_id,
        pr_start_date AS event_date,
        pr_start_time AS event_time,
        'Procedure' AS event_type,
        pr_description AS event_name
    FROM {{ ref('s_procedures') }}
),

imaging_studies AS (
    SELECT
        patient_id,
        encounter_id,
        im_date AS event_date,
        im_time AS event_time,
        'Imaging Study' AS event_type,
        modality_description AS event_name
    FROM {{ ref('s_imaging_studies') }}
),

immunizations AS (
    SELECT
        patient_id,
        encounter_id,
        imm_date AS event_date,
        imm_time AS event_time,
        'Immunization' AS event_type,
        imm_description AS event_name
    FROM {{ ref('s_immunizations') }}
),

allergies AS (
    SELECT
        patient_id,
        encounter_id,
        alg_start_date AS event_date,
        NULL AS event_time,
        'Allergy' AS event_type,
        alg_description AS event_name
    FROM {{ ref('s_allergies') }}
),

observations AS (
    SELECT      
        patient_id,
        encounter_id,
        obs_date AS event_date,
        obs_time AS event_time,
        'Observation' AS event_type,
        obs_description AS event_name
    FROM {{ ref('s_observations') }}
),

medications AS (
    SELECT
        patient_id,
        encounter_id,
        med_start_date AS event_date,
        med_start_time AS event_time,
        'Medication' AS event_type,
        med_description AS event_name
    FROM {{ ref('s_medications') }}
),

unioned AS (
    SELECT * FROM allergies
    UNION ALL
    SELECT * FROM observations
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

final AS (
    SELECT * FROM encounters

    UNION ALL

    SELECT * FROM conditions

    UNION ALL

    SELECT 
        j.journey_seq_no,
        u.* 
    FROM unioned u
    INNER JOIN journeyed j
        ON u.encounter_id = j.encounter_id
)

SELECT * FROM final
where patient_id = '3436e704-73e4-11da-241d-7adeccd97a0d'
order by journey_seq_no, event_date, event_time
