WITH transformed_patients AS ( 
    SELECT
        id,
        CASE
            WHEN deathdate IS NULL THEN 'Y'
            ELSE 'N'
        END AS is_alive,
        birthdate,
        deathdate,
        DATEDIFF(YEAR, birthdate, COALESCE(deathdate, CURRENT_DATE())) AS age,
        DATEDIFF(YEAR, deathdate, CURRENT_DATE()) AS years_since_death,
        ssn,
        drivers,
        passport AS passport_id,
        marital AS marital_status,
        {{ capitalize_value('race') }} AS race,
        {{ capitalize_value('ethnicity') }} AS ethnicity,
        gender,
        city,
        state AS patient_state,
        county,
        lat,
        lon,
        healthcare_expenses,
        healthcare_coverage
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