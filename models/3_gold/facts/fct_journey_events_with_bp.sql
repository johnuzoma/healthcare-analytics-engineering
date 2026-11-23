WITH as_of AS (
    -- the dataset's latest encounter, not today's date
    SELECT MAX(event_start_date) AS as_of_date
    FROM {{ ref('int_journey_events') }}
    WHERE is_encounter = 1
),

events AS (
    SELECT
        e.*,
        j.jny_status,
        CASE j.jny_type
            WHEN 'Chronic' THEN 365
            WHEN 'Preventive' THEN 400
            WHEN 'Acute' THEN 90
            WHEN 'Surgical' THEN 90
            ELSE 180
        END AS gap_threshold_days,
        p.death_date
    FROM {{ ref('int_journey_events') }} AS e
    LEFT JOIN {{ ref('int_journey') }} AS j
        ON e.jny_id = j.jny_id
    LEFT JOIN {{ ref('s_patients') }} AS p
        ON e.patient_id = p.id
),

encounter_nav AS (
    SELECT
        enc_id,
        LEAD(event_start_date) OVER (
            PARTITION BY jny_id
            ORDER BY event_start_date, event_start_time, enc_id
        ) AS next_jny_enc_date,
        LEAD(event_start_date) OVER (
            PARTITION BY patient_id
            ORDER BY event_start_date, event_start_time, enc_id
        ) AS next_patient_enc_date
    FROM events
    WHERE is_encounter = 1
),

typed AS (
    SELECT
        ev.*,
        n.next_jny_enc_date,
        n.next_patient_enc_date,
        a.as_of_date,
        CASE
            WHEN ev.is_encounter = 1
                AND n.next_jny_enc_date IS NOT NULL
                AND DATEDIFF(DAY, ev.event_start_date, n.next_jny_enc_date) > ev.gap_threshold_days
                THEN 'Gap in care'
            WHEN ev.is_encounter = 1
                AND n.next_patient_enc_date IS NULL
                AND ev.jny_status = 'Ongoing'
                AND ev.death_date IS NULL
                AND DATE_ADD(ev.event_start_date, ev.gap_threshold_days) < a.as_of_date
                THEN 'Lost to follow-up'
            WHEN ev.event_type = 'Careplan'
                AND (ev.event_end_date IS NULL OR ev.event_end_date > DATE_ADD(ev.event_start_date, 90))
                AND DATE_ADD(ev.event_start_date, 90) < a.as_of_date
                AND (n.next_patient_enc_date IS NULL
                     OR DATEDIFF(DAY, ev.event_start_date, n.next_patient_enc_date) > 90)
                THEN 'Careplan without follow-up'
        END AS breakpoint_type
    FROM events AS ev
    LEFT JOIN encounter_nav AS n
        ON ev.enc_id = n.enc_id
    CROSS JOIN as_of AS a
),

bp AS (
    SELECT
        *,
        CASE
            WHEN breakpoint_type IS NULL THEN NULL
            WHEN breakpoint_type = 'Careplan without follow-up' THEN DATE_ADD(event_start_date, 90)
            ELSE DATE_ADD(event_start_date, gap_threshold_days)
        END AS expected_next_date,
        CASE breakpoint_type
            WHEN 'Gap in care' THEN next_jny_enc_date
            WHEN 'Careplan without follow-up' THEN next_patient_enc_date
        END AS actual_next_date
    FROM typed
)

SELECT
    * EXCEPT (death_date, gap_threshold_days, next_jny_enc_date, next_patient_enc_date, as_of_date, jny_status),
    ROW_NUMBER() OVER (
        PARTITION BY jny_id
        ORDER BY event_start_date, event_sort, event_start_time, event_description
    ) AS event_seq_no,
    DATEDIFF(
        DAY,
        LAG(event_start_date) OVER (
            PARTITION BY jny_id
            ORDER BY event_start_date, event_sort, event_start_time, event_description
        ),
        event_start_date
    ) AS days_since_previous_event,
    DATEDIFF(DAY, MIN(event_start_date) OVER (PARTITION BY jny_id), event_start_date) AS days_since_jny_start,
    CASE WHEN breakpoint_type IS NOT NULL THEN 'Y' ELSE 'N' END AS is_breakpoint,
    CASE WHEN breakpoint_type IS NOT NULL THEN event_start_date END AS last_event_date,
    CASE breakpoint_type
        WHEN 'Gap in care'
            THEN DATEDIFF(DAY, event_start_date, next_jny_enc_date) - gap_threshold_days
        WHEN 'Lost to follow-up'
            THEN DATEDIFF(DAY, expected_next_date, as_of_date)
        WHEN 'Careplan without follow-up'
            THEN DATEDIFF(DAY, expected_next_date, COALESCE(next_patient_enc_date, as_of_date))
    END AS days_overdue,
    CASE
        WHEN breakpoint_type IS NULL THEN NULL
        WHEN actual_next_date IS NOT NULL THEN 'Y'
        ELSE 'N'
    END AS returned
FROM bp