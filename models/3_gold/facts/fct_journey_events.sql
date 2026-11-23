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
    ) AS days_since_jny_start
FROM {{ ref('int_journey_events') }}
--where ej.jny_id = '01ccaf175f777a47f8feb631eacba56f'
--order by u.event_start_date
--WHERE u.patient_id = '0288c42c-43a1-9878-4a9d-6b96caa12c40' and ej.jny_seq_no is not null
--order by ej.jny_seq_no, u.event_start_date, u.event_sort