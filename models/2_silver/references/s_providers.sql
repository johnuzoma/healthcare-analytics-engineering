SELECT
    Id AS id,
    ORGANIZATION AS organization_id,
    REGEXP_REPLACE(NAME, '[0-9]+', '') AS provider_name,
    GENDER AS gender,
    {{ capitalize_value('SPECIALITY') }} AS specialty,
    ADDRESS AS provider_address,
    CITY AS city,
    STATE AS provider_state,
    ZIP AS zip,
    LAT AS lat,
    LON AS lon,
    UTILIZATION AS utilization
FROM {{ source('bronze', 'providers') }}