WITH journey_events AS (
    SELECT
        jny_id,
        COUNT(*) AS child_events,
        COUNT_IF(event_type = 'Procedure') AS total_procedures,
        MIN(CASE WHEN event_type IN ('Procedure', 'Medication') THEN event_start_date END) AS first_treatment_date
    FROM {{ ref('int_journey_events') }}
    WHERE is_encounter = 0
    GROUP BY jny_id
)

SELECT
    je.jny_id,
    je.jny_seq_no,
    je.patient_id,
    je.jny_start_date,
    je.jny_end_date,
    DATEDIFF(DAY, je.jny_start_date, je.jny_end_date) AS duration_days,
    je.total_encounters,
    COALESCE(ev.child_events, 0) + je.total_encounters AS total_events,
    COALESCE(ev.total_procedures, 0) AS total_procedures,
    je.total_ip_admissions,
    je.entry_point,
    je.path_signature,
    jc.primary_diagnosis,
    {{ get_journey_type('jc.condition_type', 'je.total_wellness', 'je.total_encounters', 'je.total_ip_admissions', 'ev.total_procedures') }} AS jny_type,
    {{ get_journey_status('jc.primary_condition_code', 'jc.cond_end_date') }} AS jny_status,
    CASE
        WHEN p.death_date BETWEEN je.jny_start_date AND DATE_ADD(je.jny_end_date, 30) THEN 'Deceased'
        WHEN jc.cond_end_date IS NOT NULL THEN 'Resolved'
        WHEN jc.primary_condition_code IS NOT NULL THEN 'Ongoing'
        ELSE 'Not applicable'
    END AS outcome_status,
    CASE
        WHEN jc.primary_condition_code IS NOT NULL THEN
            ROW_NUMBER() OVER (
                PARTITION BY je.patient_id, jc.primary_condition_code
                ORDER BY je.jny_start_date
            )
    END AS episode_number,
    CASE
        WHEN jc.primary_condition_code IS NOT NULL THEN
            DATEDIFF(
                DAY,
                LAG(je.jny_start_date) OVER (
                    PARTITION BY je.patient_id, jc.primary_condition_code
                    ORDER BY je.jny_start_date
                ),
                je.jny_start_date
            )
    END AS days_since_last_episode,
    CASE
        WHEN jc.cond_start_date IS NOT NULL AND ev.first_treatment_date IS NOT NULL
        THEN DATEDIFF(DAY, jc.cond_start_date, ev.first_treatment_date)
    END AS days_to_first_treatment
FROM {{ ref('int_agg_journey_encounters') }} AS je
LEFT JOIN journey_events AS ev
    ON je.jny_id = ev.jny_id
LEFT JOIN {{ ref('int_journey_conditions') }} AS jc
    ON je.jny_id = jc.jny_id
LEFT JOIN {{ ref('s_patients') }} AS p
    ON je.patient_id = p.id