WITH payers AS (
    SELECT
        id,
        name
    FROM {{ source('bronze', 'payers') }}
)

,payer_transitions AS (
    SELECT
        patient AS patient_id,
        memberid AS member_id,
        start_year AS start_date_time,
        end_year AS end_date_time,
        DATEDIFF(MONTH, start_year, end_year) AS duration_months,
        DATEDIFF(MONTH, start_year, LAG(end_year) OVER (PARTITION BY patient ORDER BY start_year)) AS prior_gap_months,
        LAG(payer) OVER (PARTITION BY patient ORDER BY start_year) AS previous_payer_id,
        payer AS current_payer_id,
        secondary_payer AS secondary_payer_id,
        {{ replace_nulls('ownership') }} AS ownership,
        ROW_NUMBER() OVER (PARTITION BY patient ORDER BY start_year) - 1 AS switch_sequence
    FROM {{ source('bronze', 'payer_transitions') }}
)

SELECT
    -- patient/payer info
    pt.patient_id,
    pt.member_id,
    COALESCE(pt.previous_payer_id, 'NO_INSURANCE') AS previous_payer_id,
    pt.current_payer_id,
    pt.secondary_payer_id,
    COALESCE(prev_payer.name, 'NO_INSURANCE') AS previous_payer_name,
    curr_payer.name AS current_payer_name,
    pt.start_date_time,
    pt.end_date_time,
    pt.duration_months,
    CASE
        WHEN pt.prior_gap_months <= 12 THEN 0
        WHEN pt.prior_gap_months > 12 THEN pt.prior_gap_months
    END AS prior_coverage_gap_months,
    CASE
        WHEN curr_payer.name = 'No Insurance' THEN 'NA'
        ELSE pt.ownership
    END AS ownership,

    -- switch info
    CASE
        WHEN prev_payer.name IS NULL THEN 'N'
        WHEN prev_payer.name IS NOT NULL AND prev_payer.name = curr_payer.name THEN 'N'
        WHEN prev_payer.name IS NOT NULL AND prev_payer.name <> curr_payer.name THEN 'Y'
    END AS is_a_switch,
    pt.switch_sequence,
    MAX(pt.switch_sequence) OVER (PARTITION BY pt.patient_id) AS no_of_switches

FROM payer_transitions pt

LEFT JOIN payers prev_payer
    ON pt.previous_payer_id = prev_payer.id

LEFT JOIN payers curr_payer
    ON pt.current_payer_id = curr_payer.id