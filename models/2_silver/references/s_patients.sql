WITH transformed_patients AS ( 
    SELECT
        Id AS id,
        CASE
            WHEN DEATHDATE IS NULL THEN 'Y'
            ELSE 'N'
        END AS is_alive,
        BIRTHDATE,
        DEATHDATE,
        DATEDIFF(YEAR, BIRTHDATE, COALESCE(DEATHDATE, CURRENT_DATE())) AS age,

        DATEDIFF(YEAR, DEATHDATE, CURRENT_DATE()) AS years_since_death,
        SSN AS ssn,
        DRIVERS AS drivers,
        PASSPORT AS passport,
        PREFIX AS prefix,
        CONCAT(FIRST, ' ', LAST) AS full_name,
        SUFFIX AS suffix,
        MAIDEN AS maiden_name,
        MARITAL AS marital_status,
        INITCAP(RACE) AS race,
        INITCAP(ETHNICITY) AS ethnicity,
        GENDER AS gender,
        BIRTHPLACE AS birth_place,
        ADDRESS AS patient_address,
        CITY AS city,
        STATE AS patient_state,
        COUNTY AS county
    FROM {{ source('bronze', 'patients') }}
)

,final AS (
    SELECT
        *,
        CASE
            WHEN age < 0 OR age IS NULL THEN 'Unknown'
            WHEN age <= 19 THEN '0 - 19'
            WHEN age <= 24 THEN '20 - 24'
            WHEN age <= 64 THEN '25 - 64'
            ELSE '65+'
        END AS age_band
    FROM transformed_patients
)

SELECT * FROM final