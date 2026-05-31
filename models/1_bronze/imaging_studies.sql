SELECT
    Id AS id,
    DATE AS date_time,
    PATIENT AS patient_id,
    ENCOUNTER AS encounter_id,
    BODYSITE_CODE AS bodysite_code,
    BODYSITE_DESCRIPTION AS bodysite_description,
    MODALITY_CODE AS modality_code,
    MODALITY_DESCRIPTION AS modality_description,
    SOP_CODE AS sop_code,
    SOP_DESCRIPTION AS sop_description
FROM {{ source('synthea_ehr', 'imaging_studies') }}