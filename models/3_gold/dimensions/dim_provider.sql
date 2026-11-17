SELECT
    id,
    organization_id,
    provider_name,
    gender,
    provider_specialty,
    provider_address,
    provider_city,
    provider_state,
    zip,
    lat,
    lon,
    utilization
FROM {{ ref('s_providers') }}