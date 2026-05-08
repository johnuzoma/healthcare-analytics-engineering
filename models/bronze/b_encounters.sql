SELECT
    ID,
    DATE AS Date,
    PATIENT AS Patient_ID,
    CODE AS Code,
    DESCRIPTION AS Description,
    REASONCODE AS Reason_Code,
    REASONDESCRIPTION AS Reason_Description
FROM {{ source('source', 'encounters') }}