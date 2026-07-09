SELECT
    start_date_time,
    end_date_time,
    patient_id,
    payer_id,
    encounter_id,
    description,
    base_cost,
    payer_coverage,
    dispenses,
    total_cost,
    reason_description
FROM {{ ref('b_medications') }}