SELECT
    id AS id,
    date AS im_date_time,
    CAST(date AS DATE) AS im_date,
    DATE_FORMAT(date, 'HH:mm:ss') AS im_time,
    patient AS patient_id,
    encounter AS enc_id,
    series_uid,
    CAST(bodysite_code AS STRING) AS bodysite_code,
    bodysite_description AS bodysite_description,
    modality_code AS modality_code,
    modality_description AS modality_description,
    instance_uid,
    sop_code,
    sop_description AS sop_description,
    CAST(procedure_code AS STRING) AS procedure_code
FROM {{ source('bronze', 'imaging_studies') }}