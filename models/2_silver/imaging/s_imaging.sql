SELECT
    id,
    date_time,
    patient_id,
    encounter_id,
    bodysite_description,
    modality_description,
    sop_description
FROM {{ ref('b_imaging_studies') }}