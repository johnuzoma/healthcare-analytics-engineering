WITH proc_enc AS (
    SELECT DISTINCT encounter FROM {{ source('bronze', 'procedures') }}
),

enc AS (
    SELECT
        patient AS patient_id,
        id AS enc_id,
        provider AS provider_id,
        organization AS organization_id,
        payer AS payer_id,
        start AS enc_start_ts,
        CAST(start AS DATE) AS enc_start_date,
        DATE_FORMAT(start, 'HH:mm:ss') AS enc_start_time,
        stop AS enc_end_ts,
        CAST(stop AS DATE) AS enc_end_date,
        DATE_FORMAT(stop, 'HH:mm:ss') AS enc_end_time,
        {{ capitalize_value("
            REPLACE(encounterclass, 'urgentcare', 'urgent care')
        ") }} AS enc_class,
        CAST(reasoncode AS STRING) AS enc_reason_code,
        {{ remove_unnecessary_whitespace("reasondescription") }} AS enc_reason,
        CAST(code AS STRING) AS enc_code,
        {{ remove_unnecessary_whitespace("description") }} AS enc_description,
        base_encounter_cost AS base_enc_cost,
        total_claim_cost,
        payer_coverage,
        (total_claim_cost - payer_coverage) AS patient_responsibility,
        CASE
            WHEN payer_coverage > 0 AND p.encounter IS NOT NULL THEN 'FPP'
            ELSE 'Per Diem'
        END AS enc_billing_type,
        CASE WHEN LOWER(description) LIKE '%follow-up%' THEN 1 ELSE 0 END AS is_follow_up
    FROM {{ source('bronze', 'encounters') }} enc
    LEFT JOIN proc_enc p
        ON enc.id = p.encounter
),

admissions_within_10d AS (
    SELECT
        non_ip.enc_id AS non_ip_enc_id,
        ip.enc_description AS admitted_within_10d_description,
        ip.enc_reason AS admitted_within_10d_reason,
        ip.enc_start_ts AS admitted_within_10d_start_ts,
        ip.enc_start_date AS admitted_within_10d_start_date,
        ip.enc_start_time AS admitted_within_10d_start_time,
        ROW_NUMBER() OVER (PARTITION BY non_ip.enc_id ORDER BY ip.enc_start_ts) AS row_num
    FROM enc AS non_ip
    INNER JOIN enc AS ip
        ON non_ip.patient_id = ip.patient_id
        AND ip.enc_class = 'Inpatient'
        AND non_ip.enc_class <> 'Inpatient'
        AND ip.enc_id <> non_ip.enc_id
        AND ip.enc_start_ts BETWEEN non_ip.enc_start_ts AND DATEADD(DAY, 10, non_ip.enc_start_ts)
),

-- Step 1: base journeys. Every non-follow-up encounter starts a new journey;
-- follow-ups inherit the previous journey's number.
based AS (
    SELECT
        -- Running count of non-follow-up encounters per patient.
        -- RANGE (not ROWS) makes encounters with the same start timestamp peers,
        -- so tied rows get the same number regardless of row order.
        -- GREATEST(..., 1) covers patients whose first encounter is a follow-up
        -- (the running sum would be 0).
        -- Two tied non-follow-ups skip a number, which is fine because
        -- DENSE_RANK renumbers at the end.
        GREATEST(
            SUM(CASE WHEN is_follow_up = 1 THEN 0 ELSE 1 END) OVER (
                PARTITION BY patient_id
                ORDER BY enc_start_ts
                RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ),
            1
        ) AS base_journey_seq_no,
        enc.*,
        -- enc_id tiebreaker keeps LAG deterministic when timestamps tie
        DATEDIFF(
            DAY,
            LAG(enc_start_date) OVER (PARTITION BY patient_id ORDER BY enc_start_ts, enc_id),
            enc_start_date
        ) AS days_since_previous_encounter,

        -- admissions within 10 days
        CASE
            WHEN enc.enc_class = 'Inpatient' THEN 'NA'
            WHEN adm.non_ip_enc_id IS NOT NULL THEN 'Y'
            ELSE 'N'
        END AS is_admission_within_10d,
        {{ remove_unnecessary_whitespace("
            COALESCE(
                adm.admitted_within_10d_reason,
                adm.admitted_within_10d_description
            )
        ") }} AS admitted_within_10d_reason,
        adm.admitted_within_10d_start_date,
        adm.admitted_within_10d_start_time
    FROM enc
    LEFT JOIN admissions_within_10d AS adm
        ON enc.enc_id = adm.non_ip_enc_id
        AND adm.row_num = 1
),

-- Step 2: merge journeys that share a reason code within 180 days.
-- Candidates are non-follow-up encounters that have a reason code.
reasoned AS (
    SELECT
        patient_id,
        enc_id,
        enc_start_ts,
        enc_reason_code,
        base_journey_seq_no
    FROM based
    WHERE enc_reason_code IS NOT NULL
        AND is_follow_up = 0
),

-- Previous encounter timestamp for the same patient and reason
gaps AS (
    SELECT
        *,
        LAG(enc_start_ts) OVER (
            PARTITION BY patient_id, enc_reason_code
            ORDER BY enc_start_ts, enc_id
        ) AS prev_ts
    FROM reasoned
),

-- Gaps-and-islands: flag a new chain when the gap exceeds 180 days,
-- then a running sum of the flags gives each chain a number.
-- The first row has a NULL prev_ts, so the comparison is NULL and counts as 0.
chained AS (
    SELECT
        *,
        SUM(CASE WHEN DATEDIFF(enc_start_ts, prev_ts) > 180 THEN 1 ELSE 0 END) OVER (
            PARTITION BY patient_id, enc_reason_code
            ORDER BY enc_start_ts, enc_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS chain_no
    FROM gaps
),

-- Earliest base journey in each chain: later journeys will point back to it
chain_min AS (
    SELECT
        patient_id,
        base_journey_seq_no,
        MIN(base_journey_seq_no) OVER (
            PARTITION BY patient_id, enc_reason_code, chain_no
        ) AS chain_target
    FROM chained
),

journey_map AS (
    SELECT
        -- Renumber the final journeys 1, 2, 3 with no gaps.
        -- Merged journeys use their target number, unmerged ones keep their own.
        DENSE_RANK() OVER (
            PARTITION BY b.patient_id
            ORDER BY COALESCE(m.merged_journey_seq_no, b.base_journey_seq_no)
        ) AS jny_seq_no,
        b.*
    FROM based AS b
    LEFT JOIN (
        -- A base journey can sit in several chains (one per reason code),
        -- so collapse to its lowest target to get one row per journey
        SELECT
            patient_id,
            base_journey_seq_no,
            MIN(chain_target) AS merged_journey_seq_no
        FROM chain_min
        GROUP BY patient_id, base_journey_seq_no
    ) AS m
        ON b.patient_id = m.patient_id
        AND b.base_journey_seq_no = m.base_journey_seq_no
)

SELECT
    MD5(
        CONCAT_WS('|', CAST(jny_seq_no AS STRING), patient_id)
    ) AS jny_id,
    *
FROM journey_map