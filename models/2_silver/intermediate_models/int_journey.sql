WITH enc AS (
    -- one row per encounter, so multi-condition duplicates don't inflate counts or cost
    SELECT
        jny_id, jny_seq_no, patient_id, enc_id, enc_class,
        enc_start_ts, enc_start_date, enc_end_date,
        provider_id, organization_id, payer_id, total_claim_cost
    FROM {{ ref('s_encounter_journeys') }}
),

condition_info AS (
    SELECT
        jny_id,
        condition_code AS primary_condition_code,
        diagnosis AS primary_diagnosis,
        cond_start_date,
        cond_end_date,
        condition_type
    FROM (
        SELECT
            e.jny_id,
            e.jny_seq_no,
            c.cond_start_date,
            c.cond_end_date,
            c.condition_type,
            c.condition_code,
            COALESCE(c.condition_name, 'No diagnosis') AS diagnosis,
            ROW_NUMBER() OVER (PARTITION BY e.jny_id ORDER BY c.cond_start_date, c.condition_code ASC NULLS LAST) AS row_num
        FROM enc e
        LEFT JOIN {{ ref('s_conditions') }} c
            ON e.enc_id = c.enc_id
            AND LOWER(c.condition_name) NOT LIKE '%(finding)%'
            AND LOWER(c.condition_name) NOT LIKE '%(situation)%'
            AND LOWER(c.condition_name) <> 'normal pregnancy'
    ) sub
    WHERE row_num = 1
),

journey_events AS (
    SELECT
        jny_id,
        COUNT(*) AS child_events,
        COUNT_IF(event_type = 'Procedure') AS total_procedures,
        COUNT_IF(event_type = 'Medication') AS total_medications,
        MIN(CASE WHEN event_type IN ('Procedure', 'Medication') THEN event_start_date END) AS first_treatment_date
    FROM {{ ref('int_journey_events') }}
    WHERE is_encounter = 0
    GROUP BY jny_id
),

journey_encounters AS (
    SELECT
        jny_id,
        jny_seq_no,
        patient_id,
        MIN(enc_start_date) AS jny_start_date,
        MAX(enc_end_date) AS jny_end_date,
        COUNT(*) AS total_encounters,
        COUNT_IF(enc_class = 'Inpatient') AS total_ip_admissions,
        COUNT_IF(enc_class IN ('Emergency', 'Urgent Care')) AS total_emergencies,
        COUNT_IF(enc_class = 'Wellness') AS total_wellness,
        SUM(total_claim_cost) AS total_cost,
        COUNT(DISTINCT provider_id) AS distinct_providers,
        COUNT(DISTINCT organization_id) AS distinct_organizations,
        COUNT(DISTINCT payer_id) AS distinct_payers,
        MIN_BY(enc_class, enc_start_ts) AS entry_point,
        ARRAY_JOIN(
            TRANSFORM(ARRAY_SORT(COLLECT_LIST(STRUCT(enc_start_ts, enc_class))), x -> x.enc_class),
            ' > '
        ) AS path_signature
    FROM enc
    GROUP BY jny_id, jny_seq_no, patient_id
),

readmissions AS (
    SELECT jny_id, 1 AS readmitted_30d
    FROM (
        SELECT
            jny_id,
            enc_start_date,
            LAG(enc_end_date) OVER (PARTITION BY patient_id ORDER BY enc_start_ts) AS prev_ip_end
        FROM enc
        WHERE enc_class = 'Inpatient'
    )
    WHERE DATEDIFF(DAY, prev_ip_end, enc_start_date) BETWEEN 0 AND 30
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
    COALESCE(ev.total_medications, 0) AS total_medications,
    je.total_ip_admissions,
    je.total_emergencies,
    je.total_cost,
    je.distinct_providers,
    je.distinct_organizations,
    je.distinct_payers,
    je.entry_point,
    je.path_signature,
    COALESCE(r.readmitted_30d, 0) AS readmitted_30d,
    ci.primary_diagnosis,
    CASE
        WHEN ci.condition_type IS NOT NULL THEN ci.condition_type
        WHEN je.total_wellness = je.total_encounters THEN 'Preventive'
        WHEN je.total_ip_admissions > 0 AND COALESCE(ev.total_procedures, 0) > 0 THEN 'Surgical'
        ELSE 'Unclassified'
    END AS jny_type,
    CASE
        WHEN ci.primary_condition_code IS NULL OR ci.cond_end_date IS NOT NULL THEN 'Completed'
        ELSE 'Ongoing'
    END AS jny_status,
    CASE
        WHEN p.death_date BETWEEN je.jny_start_date AND DATE_ADD(je.jny_end_date, 30) THEN 'Deceased'
        WHEN ci.cond_end_date IS NOT NULL THEN 'Resolved'
        WHEN ci.primary_condition_code IS NOT NULL THEN 'Ongoing'
        ELSE 'Not applicable'
    END AS outcome_status,
    CASE
        WHEN ci.primary_condition_code IS NOT NULL THEN
            ROW_NUMBER() OVER (
                PARTITION BY je.patient_id, ci.primary_condition_code
                ORDER BY je.jny_start_date
            )
    END AS episode_number,
    CASE
        WHEN ci.primary_condition_code IS NOT NULL THEN
            DATEDIFF(
                DAY,
                LAG(je.jny_start_date) OVER (
                    PARTITION BY je.patient_id, ci.primary_condition_code
                    ORDER BY je.jny_start_date
                ),
                je.jny_start_date
            )
    END AS days_since_last_episode,
    CASE
        WHEN ci.cond_start_date IS NOT NULL AND ev.first_treatment_date IS NOT NULL
        THEN DATEDIFF(DAY, ci.cond_start_date, ev.first_treatment_date)
    END AS days_to_first_treatment
FROM journey_encounters AS je
LEFT JOIN journey_events AS ev
    ON je.jny_id = ev.jny_id
LEFT JOIN readmissions AS r
    ON je.jny_id = r.jny_id
LEFT JOIN condition_info AS ci
    ON je.jny_id = ci.jny_id
LEFT JOIN {{ ref('s_patients') }} AS p
    ON je.patient_id = p.id