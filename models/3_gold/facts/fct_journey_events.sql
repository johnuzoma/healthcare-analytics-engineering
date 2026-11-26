WITH base AS (
    SELECT
        *,
        LAST_VALUE(
            CASE WHEN event_type = 'Inpatient' THEN event_end_date END,
            TRUE -- skip non-inpatient rows
        ) OVER (
            PARTITION BY patient_id ORDER BY event_start_date, event_sort, event_start_time
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING -- current row is excluded
        ) AS prev_ip_end_date
    FROM {{ ref('int_journey_events') }}
)

SELECT
    *,
    ROW_NUMBER() OVER (
        PARTITION BY jny_id
        ORDER BY event_start_date, event_sort, event_start_time
    ) AS event_seq_no,
    DATEDIFF(
        DAY, 
        LAG(event_start_date) OVER (PARTITION BY jny_id ORDER BY event_start_date, event_sort, event_start_time),
        event_start_date
    ) AS days_since_previous_event,
    DATEDIFF(
        DAY, 
        MIN(event_start_date) OVER (PARTITION BY jny_id), 
        event_start_date
    ) AS days_since_jny_start,
    CASE
        WHEN event_type <> 'Inpatient' THEN 'NA'
        WHEN prev_ip_end_date IS NULL THEN 'NA'
        WHEN DATEDIFF(DAY, prev_ip_end_date, event_start_date) BETWEEN 0 AND 30 THEN 'Y'
        ELSE 'N'
    END AS is_readmission_within_30d
FROM base