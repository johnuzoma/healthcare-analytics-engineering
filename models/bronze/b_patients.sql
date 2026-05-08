SELECT
    ID,
    BIRTHDATE AS Birth_Date,
    DEATHDATE AS Death_Date,
    SSN,
    DRIVERS AS Drivers,
    PASSPORT AS Passport,
    PREFIX AS Prefix,
    FIRST AS First_Name,
    LAST AS Last_Name,
    SUFFIX AS Suffix,
    MAIDEN AS Maiden_Name,
    MARITAL AS Marital_Status,
    RACE AS Race,
    ETHNICITY AS Ethnicity,
    GENDER AS Gender,
    BIRTHPLACE AS Birth_Place,
    ADDRESS AS Home_Address
FROM {{ source('source', 'patients') }}