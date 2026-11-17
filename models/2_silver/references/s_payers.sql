SELECT
    id,
    CASE name
        WHEN 'NO_INSURANCE' THEN 'No Insurance'
        WHEN 'UnitedHealthcare' THEN 'United Healthcare'
        ELSE name
    END AS payer_name,
    address AS payer_address,
    city,
    state_headquartered,
    zip,
    phone,
    amount_covered,
    amount_uncovered,
    revenue,
    covered_encounters,
    uncovered_encounters,
    covered_medications,
    uncovered_medications,
    covered_procedures,
    uncovered_procedures,
    covered_immunizations,
    uncovered_immunizations,
    unique_customers,
    qols_avg AS avg_qols,
    member_months
FROM {{ source('bronze', 'payers') }}