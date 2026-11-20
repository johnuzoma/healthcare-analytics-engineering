WITH enc AS (
    SELECT
        patient AS patient_id,
        id AS encounter_id,
        start AS enc_start_ts,
        CAST(reasoncode AS STRING) AS encounter_reason_code,
        reasondescription AS encounter_reason,
        provider AS provider_id,
        CASE WHEN LOWER(description) LIKE '%follow-up%' THEN 1 ELSE 0 END AS is_follow_up
    FROM {{ source('bronze', 'encounters') }}
),

visits AS (
    -- one row per patient and timestamp, so duplicated rows
    -- (multiple conditions) don't inflate the running count
    SELECT
        patient_id,
        enc_start_ts,
        MIN(is_follow_up) AS all_follow_up
    FROM enc
    GROUP BY patient_id, enc_start_ts
),

numbered AS (
    SELECT
        patient_id,
        enc_start_ts,
        GREATEST(
            SUM(CASE WHEN all_follow_up = 1 THEN 0 ELSE 1 END) OVER (
                PARTITION BY patient_id
                ORDER BY enc_start_ts
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ),
            1
        ) AS journey_seq_no
    FROM visits
),

based AS (
    SELECT
        n.journey_seq_no AS base_journey_seq_no,
        enc.*
    FROM enc
    INNER JOIN numbered AS n
        ON enc.patient_id = n.patient_id
        AND enc.enc_start_ts = n.enc_start_ts
),

reasoned AS (
    SELECT DISTINCT
        patient_id,
        encounter_id,
        enc_start_ts,
        encounter_reason_code,
        base_journey_seq_no
    FROM based
    WHERE encounter_reason_code IS NOT NULL
        AND is_follow_up = 0
),

gaps AS (
    SELECT
        *,
        LAG(enc_start_ts) OVER (
            PARTITION BY patient_id, encounter_reason_code
            ORDER BY enc_start_ts, encounter_id
        ) AS prev_ts
    FROM reasoned
),

chained AS (
    SELECT
        *,
        SUM(CASE WHEN DATEDIFF(enc_start_ts, prev_ts) > 180 THEN 1 ELSE 0 END) OVER (
            PARTITION BY patient_id, encounter_reason_code
            ORDER BY enc_start_ts, encounter_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS chain_no
    FROM gaps
),

chain_min AS (
    SELECT
        patient_id,
        base_journey_seq_no,
        MIN(base_journey_seq_no) OVER (
            PARTITION BY patient_id, encounter_reason_code, chain_no
        ) AS chain_target
    FROM chained
),

journey_map AS (
    SELECT
        patient_id,
        base_journey_seq_no,
        MIN(chain_target) AS merged_journey_seq_no
    FROM chain_min
    GROUP BY patient_id, base_journey_seq_no
)

SELECT
    DENSE_RANK() OVER (
        PARTITION BY b.patient_id
        ORDER BY COALESCE(m.merged_journey_seq_no, b.base_journey_seq_no)
    ) AS journey_seq_no,
    b.patient_id,
    b.encounter_id,
    b.enc_start_ts,
    b.encounter_reason,
    b.is_follow_up,
    b.provider_id
FROM based AS b
LEFT JOIN journey_map AS m
    ON b.patient_id = m.patient_id
    AND b.base_journey_seq_no = m.base_journey_seq_no