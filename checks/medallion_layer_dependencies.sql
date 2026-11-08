WITH nodes AS (
    SELECT 
        unique_id,
        CASE
            WHEN schema_name = '1_bronze' THEN 'bronze'
        END AS layer 
    FROM {{ info_schema('sources') }}
    
    UNION ALL

    SELECT
        unique_id,
        CASE
            WHEN schema_name = '2_silver' THEN 'silver'
            WHEN schema_name = '3_gold' THEN 'gold'
        END AS layer
    FROM {{ info_schema('models') }}
),

allowed (parent_layer, child_layer) AS (
    VALUES
        ('bronze', 'silver'),
        ('silver', 'gold')
)

SELECT
    e.parent_unique_id,
    e.child_unique_id,
    p.layer AS parent_layer,
    c.layer AS child_layer
FROM {{ info_schema('edges') }} AS e
INNER JOIN nodes AS p ON p.unique_id = e.parent_unique_id
INNER JOIN nodes AS c ON c.unique_id = e.child_unique_id
LEFT JOIN allowed AS a
    ON a.parent_layer = p.layer
    AND a.child_layer = c.layer
WHERE a.parent_layer IS NULL