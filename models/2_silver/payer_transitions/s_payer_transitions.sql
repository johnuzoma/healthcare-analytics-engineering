WITH payer_transitions AS (
    SELECT
        patient_id,
        start_year,
        end_year,
        (end_year - start_year) AS duration,
        payer_id,
        COALESCE(ownership, 'Unknown') AS ownership,
        ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY start_year) - 1 AS switch_sequence
    FROM {{ ref('b_payer_transitions') }}
)

SELECT
    *,
    MAX(switch_sequence) OVER (PARTITION BY patient_id) AS total_no_of_switches
FROM payer_transitions