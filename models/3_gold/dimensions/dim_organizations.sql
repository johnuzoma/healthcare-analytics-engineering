SELECT
    id,
    org_name,
    org_address,
    city,
    org_state,
    zip,
    lat,
    lon,
    phone,
    revenue,
    utilization
FROM {{ ref('s_organizations') }}