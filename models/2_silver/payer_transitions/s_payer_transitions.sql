WITH payers AS (
    SELECT
        Id AS id,
        NAME AS name
    FROM {{ source('bronze', 'payers') }}
)

,payer_transitions AS (
    SELECT
        PATIENT AS patient_id,
        START_YEAR AS start_year,
        END_YEAR AS end_year,
        (END_YEAR - START_YEAR) AS duration_years,
        START_YEAR - LAG(END_YEAR) OVER (PARTITION BY PATIENT ORDER BY START_YEAR) AS prior_gap_years,
        LAG(PAYER) OVER (PARTITION BY PATIENT ORDER BY START_YEAR) AS previous_payer_id,
        PAYER AS current_payer_id,
        COALESCE(OWNERSHIP, 'Unknown') AS ownership,
        ROW_NUMBER() OVER (PARTITION BY PATIENT ORDER BY START_YEAR) - 1 AS switch_sequence
    FROM {{ source('bronze', 'payer_transitions') }}
)

SELECT
    -- patient/payer info
    PT.patient_id,
    COALESCE(PT.previous_payer_id, 'NO_INSURANCE') AS previous_payer_id,
    PT.current_payer_id,
    COALESCE(prev_payer.name, 'NO_INSURANCE') AS previous_payer_name,
    curr_payer.NAME AS current_payer_name,
    PT.start_year,
    PT.end_year,
    PT.duration_years,
    CASE
        WHEN PT.prior_gap_years IN (1,0) THEN 0
        WHEN PT.prior_gap_years > 1 THEN PT.prior_gap_years
    END AS prior_coverage_gap_years,
    CASE
        WHEN curr_payer.name = 'NO_INSURANCE' THEN 'Not Applicable'
        ELSE PT.ownership
    END AS ownership,

    -- switch info
    CASE
        WHEN prev_payer.name IS NULL THEN 0
        WHEN prev_payer.name IS NOT NULL AND prev_payer.name = curr_payer.name THEN 0
        WHEN prev_payer.name IS NOT NULL AND prev_payer.name <> curr_payer.name THEN 1
    END AS is_a_switch,
    PT.switch_sequence,
    MAX(PT.switch_sequence) OVER (PARTITION BY PT.patient_id) AS no_of_switches

FROM payer_transitions PT

LEFT JOIN payers prev_payer
    ON PT.previous_payer_id = prev_payer.id

LEFT JOIN payers curr_payer
    ON PT.current_payer_id = curr_payer.id