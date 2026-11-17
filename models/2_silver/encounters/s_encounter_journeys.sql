WITH joined AS (
    SELECT
        enc.patient AS patient_id,
        enc.id AS encounter_id,
        enc.start AS enc_start_ts,
        {{ capitalize_value("REPLACE(enc.encounterclass, 'urgentcare', 'urgent care')") }} AS encounter_class,
        enc.description AS encounter_description,
        CAST(enc.start AS DATE) AS enc_start_date,
        DATE_FORMAT(enc.start, 'HH:mm:ss') AS enc_start_time,
        CAST(con.code AS STRING) AS condition_code,
        con.description AS condition_name,
        CAST(con.start AS DATE) AS cond_start_date,
        CAST(con.stop AS DATE) AS cond_end_date,
        MIN(CAST(con.start AS DATE)) OVER (PARTITION BY enc.id) AS anchor_date
    FROM {{ source('bronze', 'encounters') }} AS enc
    LEFT JOIN {{ source('bronze', 'conditions') }} AS con
        ON enc.id = con.encounter
),

base AS (
    SELECT
        *,
        LAST_VALUE(
            CASE WHEN condition_code IS NOT NULL
                 THEN STRUCT(anchor_date AS s, cond_end_date AS e) END,
            TRUE
        ) OVER (
            PARTITION BY patient_id
            ORDER BY enc_start_ts, encounter_id, condition_code
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS last_cond
    FROM joined
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
            CASE WHEN anchor_date IS NOT NULL THEN anchor_date
                WHEN is_follow_up = 1 THEN last_cond.s
                ELSE enc_start_date END,
            CASE WHEN anchor_date IS NOT NULL OR is_follow_up = 1 THEN 0 ELSE 1 END
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
where patient_id = '3436e704-73e4-11da-241d-7adeccd97a0d'
order by enc_start_date,
    enc_start_time