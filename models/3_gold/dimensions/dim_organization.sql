SELECT
    id,
    org_name,
    org_address,
    org_city,
    org_state,
    zip,
    lat,
    lon,
    phone,
    revenue,
    utilization
FROM {{ ref('s_organizations') }}