SELECT
    Id AS id,
    ORGANIZATION AS organization_id,
    NAME AS provider_name,
    GENDER AS gender,
    SPECIALITY AS specialty,
    ADDRESS AS provider_address,
    CITY AS city,
    STATE AS provider_state,
    ZIP AS zip,
    LAT AS lat,
    LON AS lon,
    UTILIZATION AS utilization
FROM {{ source('bronze', 'providers') }}