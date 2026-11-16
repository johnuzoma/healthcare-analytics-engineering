WITH base AS (
    SELECT
        enc.patient AS patient_id,
        enc.id AS encounter_id,
        {{ capitalize_value("
            REPLACE(enc.encounterclass, 'urgentcare', ('urgent care'))
        ") }} AS encounter_class,
        enc.description AS encounter_description,
        CAST(enc.start AS DATE) AS enc_start_date,
        DATE_FORMAT(enc.start, 'HH:mm:ss') AS enc_start_time,
        CAST(con.code AS STRING) AS condition_code,
        con.description AS condition_name,
        con.start AS cond_start_date,
        LAST_VALUE(
            CASE WHEN con.code IS NOT NULL
                 THEN STRUCT(CAST(con.code AS STRING) AS code, con.start AS s, con.stop AS e) END,
            TRUE -- skip nulls (meaning it must find the last real condition)
        ) OVER (
            PARTITION BY enc.patient -- keeps each patient separate
            ORDER BY enc.start, enc.id, con.code -- puts encounters in time order and added tiebreakers
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING -- covers all rows before the current row
        ) AS last_cond
    FROM {{ source('bronze', 'encounters') }} AS enc
    LEFT JOIN {{ source('bronze', 'conditions') }} AS con
        ON enc.id = con.encounter
),

anchored AS (
    SELECT
        *,
        CASE
            WHEN condition_code IS NULL
                AND LOWER(encounter_class) <> 'wellness'
                AND enc_start_date BETWEEN last_cond.s AND DATE_ADD(last_cond.e, 14)
            THEN 1
            ELSE 0
        END AS is_follow_up
    FROM base
)

SELECT
    DENSE_RANK() OVER (
        PARTITION BY patient_id
        ORDER BY
            CASE WHEN condition_code IS NOT NULL THEN cond_start_date
                WHEN is_follow_up = 1 THEN last_cond.s
                ELSE enc_start_date END,
            CASE WHEN condition_code IS NOT NULL THEN condition_code
                WHEN is_follow_up = 1 THEN last_cond.code
                ELSE 'PREVENTIVE' END
    ) AS journey_seq_no,
    patient_id,
    encounter_id,
    enc_start_date,
    enc_start_time,
    encounter_class,
    encounter_description,
    cond_start_date,
    condition_code,
    condition_name
FROM anchored