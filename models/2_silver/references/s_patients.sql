WITH transformed_patients AS (
    SELECT
        id,
        CASE
            WHEN death_date IS NULL THEN 'Y'
            ELSE 'N'
        END AS is_alive,
        birth_date,
        death_date,
        DATEDIFF(YEAR, birth_date, COALESCE(death_date, CURRENT_DATE())) AS age,

        DATEDIFF(YEAR, death_date, CURRENT_DATE()) AS years_since_death,
        ssn,
        drivers,
        passport,
        prefix,
        CONCAT(first_name, ' ', last_name) AS full_name,
        suffix,
        maiden_name,
        marital_status,
        INITCAP(race) AS race,
        INITCAP(ethnicity) AS ethnicity,
        gender,
        birth_place,
        address AS patient_address,
        city,
        state AS patient_state,
        county
    FROM {{ ref('b_patients') }}
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