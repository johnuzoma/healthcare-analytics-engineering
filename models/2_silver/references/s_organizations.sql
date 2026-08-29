SELECT
    Id AS id,
    NAME AS org_name,
    ADDRESS AS org_address,
    CITY AS city,
    STATE AS org_state,
    ZIP AS zip,
    LAT AS lat,
    LON AS lon,
    PHONE AS phone,
    REVENUE AS revenue,
    UTILIZATION AS utilization
FROM {{ source('bronze', 'organizations') }}