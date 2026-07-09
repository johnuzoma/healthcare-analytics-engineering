SELECT
    id,
    organization_id,
    name,
    gender,
    specialty,
    address,
    city,
    state,
    zip,
    lat,
    lon,
    utilization
FROM {{ ref('b_providers') }}