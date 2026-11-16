SELECT
    Id AS id,
    DATE AS im_date_time,
    CAST(DATE AS DATE) AS im_date,
    DATE_FORMAT(DATE, 'HH:mm:ss') AS im_time,
    PATIENT AS patient_id,
    ENCOUNTER AS encounter_id,
    CAST(BODYSITE_CODE AS STRING) AS bodysite_code,
    BODYSITE_DESCRIPTION AS bodysite_description,
    MODALITY_CODE AS modality_code,
    MODALITY_DESCRIPTION AS modality_description,
    CAST(SOP_CODE AS STRING) AS sop_code,
    SOP_DESCRIPTION AS sop_description
FROM {{ source('bronze', 'imaging_studies') }}