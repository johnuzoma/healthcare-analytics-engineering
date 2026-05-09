SELECT
    DATE AS Date,
    PATIENT AS Patient_ID,
    ENCOUNTER AS Encounter_ID,
    CODE AS Code,
    DESCRIPTION AS Description,
    VALUE AS Value,
    UNITS AS Unit
FROM {{ source('ehr', 'observations') }}