SELECT
    id,
    organization_id,
    provider_name,
    gender,
    specialty,
    provider_address,
    city,
    provider_state,
    zip,
    lat,
    lon,
    utilization
FROM {{ ref('s_providers') }}