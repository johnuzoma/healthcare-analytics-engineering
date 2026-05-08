SELECT
    START AS Start_Date,
    STOP AS End_Date,
    PATIENT AS Patient_ID,
    ENCOUNTER AS Encounter_ID,
    CODE AS Code,
    DESCRIPTION AS Description
FROM {{ source('source', 'conditions') }}