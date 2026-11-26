WITH total_procedures AS (
    SELECT
        jny_id,
        COUNT(*) AS total_procedures
    FROM {{ ref('int_journey_events') }}
    WHERE event_type = 'Procedure'
    GROUP BY jny_id
),

jny AS (
    SELECT
        je.jny_id,
        {{ get_journey_status('jc.primary_condition_code', 'jc.cond_end_date') }} AS jny_status,
        {{ get_journey_type('jc.condition_type', 'je.total_wellness', 'je.total_encounters', 'je.total_ip_admissions', 'tp.total_procedures') }} AS jny_type
    FROM {{ ref('int_agg_journey_encounters') }} AS je
    LEFT JOIN {{ ref('int_journey_conditions') }} AS jc
        ON je.jny_id = jc.jny_id
    LEFT JOIN total_procedures AS tp
        ON je.jny_id = tp.jny_id
),

gap_threshold_assignment_to_jny AS (
    SELECT
        jny_id,
        jny_status,
        CASE jny_type
            WHEN 'Chronic' THEN 365
            WHEN 'Preventive' THEN 400
            WHEN 'Acute' THEN 90
            WHEN 'Surgical' THEN 90
            ELSE 180
        END AS gap_threshold_days
    FROM jny
),

open_careplans AS (
    SELECT enc_id
    FROM {{ ref('s_careplans') }}
    GROUP BY enc_id
    HAVING MAX(CASE WHEN cp_end_date IS NULL OR cp_end_date > DATEADD(cp_start_date, 90) THEN 1 ELSE 0 END) = 1
),

gap_in_care AS (
    SELECT
        e.jny_id, e.patient_id, e.enc_id, e.provider_id, e.organization_id, e.payer_id,
        'Gap in care' AS breakpoint_type,
        e.enc_start_date AS last_event_date,
        DATEADD(e.enc_start_date, j.gap_threshold_days) AS expected_next_date,
        e.next_jny_enc_date AS actual_next_date,
        DATEDIFF(DAY, e.enc_start_date, e.next_jny_enc_date) - j.gap_threshold_days AS days_overdue,
        CASE WHEN e.payer_id <> e.next_jny_payer_id THEN 'Y' ELSE 'N' END AS payer_changed,
        CASE WHEN e.provider_id <> e.next_jny_provider_id THEN 'Y' ELSE 'N' END AS provider_changed,
        CASE WHEN e.organization_id <> e.next_jny_organization_id THEN 'Y' ELSE 'N' END AS hospital_changed
    FROM {{ ref('int_journey_encounter_windows') }} e
    INNER JOIN gap_threshold_assignment_to_jny j
        ON e.jny_id = j.jny_id
    WHERE DATEDIFF(DAY, e.enc_start_date, e.next_jny_enc_date) > j.gap_threshold_days
),

lost_to_follow_up AS (
    SELECT
        e.jny_id, e.patient_id, e.enc_id, e.provider_id, e.organization_id, e.payer_id,
        'Lost to follow-up' AS breakpoint_type,
        e.enc_start_date AS last_event_date,
        DATEADD(e.enc_start_date, j.gap_threshold_days) AS expected_next_date,
        CAST(NULL AS DATE) AS actual_next_date,
        DATEDIFF(DAY, DATEADD(e.enc_start_date, j.gap_threshold_days), m.as_of_date) AS days_overdue,
        'NA' AS payer_changed,
        'NA' AS provider_changed,
        'NA' AS hospital_changed
    FROM {{ ref('int_journey_encounter_windows') }} e
    INNER JOIN gap_threshold_assignment_to_jny j
        ON e.jny_id = j.jny_id
        AND j.jny_status = 'Ongoing'
    INNER JOIN {{ ref('s_patients') }} p
        ON e.patient_id = p.id
        AND p.death_date IS NULL
    CROSS JOIN {{ ref('s_encounter_max_start_date') }} m
    WHERE e.next_patient_enc_date IS NULL
        AND DATEADD(e.enc_start_date, j.gap_threshold_days) < m.as_of_date
),

careplan_no_follow_up AS (
    SELECT
        e.jny_id, e.patient_id, e.enc_id, e.provider_id, e.organization_id, e.payer_id,
        'Careplan without follow-up' AS breakpoint_type,
        e.enc_start_date AS last_event_date,
        DATEADD(e.enc_start_date, 90) AS expected_next_date,
        e.next_patient_enc_date AS actual_next_date,
        DATEDIFF(DAY, DATEADD(e.enc_start_date, 90), COALESCE(e.next_patient_enc_date, m.as_of_date)) AS days_overdue,
        CASE
            WHEN e.next_patient_enc_date IS NULL THEN 'NA'
            WHEN e.payer_id <> e.next_patient_payer_id THEN 'Y' 
            ELSE 'N' 
        END AS payer_changed,
        CASE 
            WHEN e.next_patient_enc_date IS NULL THEN 'NA'
            WHEN e.provider_id <> e.next_patient_provider_id THEN 'Y'
            ELSE 'N' 
        END AS provider_changed,
        CASE 
            WHEN e.next_patient_enc_date IS NULL THEN 'NA'
            WHEN e.organization_id <> e.next_patient_organization_id THEN 'Y' 
            ELSE 'N' 
        END AS hospital_changed
    FROM {{ ref('int_journey_encounter_windows') }} e
    INNER JOIN open_careplans cp
        ON e.enc_id = cp.enc_id
    CROSS JOIN {{ ref('s_encounter_max_start_date') }} AS m
    WHERE DATEADD(e.enc_start_date, 90) < m.as_of_date
        AND (e.next_patient_enc_date IS NULL
             OR DATEDIFF(DAY, e.enc_start_date, e.next_patient_enc_date) > 90)
),

unioned AS (
    SELECT * FROM gap_in_care
    UNION ALL
    SELECT * FROM lost_to_follow_up
    UNION ALL
    SELECT * FROM careplan_no_follow_up
)
select count(*) from (
SELECT
    MD5(CONCAT_WS('|', jny_id, enc_id, breakpoint_type)) AS breakpoint_id,
    *,
    CASE WHEN actual_next_date IS NULL THEN 'N' ELSE 'Y' END AS returned,
    DATEDIFF(DAY, last_event_date, actual_next_date) AS days_to_return
FROM unioned) sub