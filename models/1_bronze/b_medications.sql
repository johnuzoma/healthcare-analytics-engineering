SELECT
    START AS start_date_time,
    STOP AS end_date_time,
    PATIENT AS patient_id,
    PAYER AS payer_id,
    ENCOUNTER AS encounter_id,
    CODE AS code,
    DESCRIPTION AS description,
    BASE_COST AS base_cost,
    PAYER_COVERAGE AS payer_coverage,
    DISPENSES AS dispenses,
    TOTALCOST AS total_cost,
    REASONCODE AS reason_code,
    REASONDESCRIPTION AS reason_description
FROM {{ source('synthea_ehr', 'medications') }}