SELECT
    id AS id,
    {{ capitalize_value('name') }} AS org_name,
    {{ capitalize_value('address') }} AS org_address,
    {{ capitalize_value('city') }} AS org_city,
    state AS org_state,
    zip,
    lat,
    lon,
    phone,
    revenue,
    utilization
FROM {{ source('bronze', 'organizations') }}