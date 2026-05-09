SELECT
    DATE AS Date,
    PATIENT AS Patient_ID,
    ENCOUNTER AS Encounter_ID,
    CODE AS Code,  
    DESCRIPTION AS Description
FROM {{ source('ehr', 'immunizations') }}