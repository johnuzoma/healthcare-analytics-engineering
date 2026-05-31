SELECT
    Id AS id,
    NAME AS name,
    ADDRESS AS address,
    CITY AS city,
    STATE AS state,
    ZIP AS zip,
    LAT AS lat,
    LON AS lon,
    PHONE AS phone,
    REVENUE AS revenue,
    UTILIZATION AS utilization
FROM {{ source('synthea_ehr', 'organizations') }}