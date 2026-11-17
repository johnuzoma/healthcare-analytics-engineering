SELECT
    id AS id,
    organization AS organization_id,
    REGEXP_REPLACE(name, '[0-9]+', '') AS provider_name,
    gender,
    {{ capitalize_value('speciality') }} AS provider_specialty,
    {{ capitalize_value('address') }} AS provider_address,
    {{ capitalize_value('city') }} AS provider_city,
    state AS provider_state,
    zip,
    lat,
    lon,
    utilization
FROM {{ source('bronze', 'providers') }}