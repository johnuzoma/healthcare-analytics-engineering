SELECT
    id,
    name,
    address,
    city,
    state,
    zip,
    lat,
    lon,
    phone,
    revenue,
    utilization
FROM {{ ref('b_organizations') }}