SELECT
    Id AS id,
    ORGANIZATION AS organization_id,
    NAME AS name,
    GENDER AS gender,
    SPECIALITY AS specialty,
    ADDRESS AS address,
    CITY AS city,
    STATE AS state,
    ZIP AS zip,
    LAT AS lat,
    LON AS lon,
    UTILIZATION AS utilization
FROM {{ source('synthea_ehr', 'providers') }}