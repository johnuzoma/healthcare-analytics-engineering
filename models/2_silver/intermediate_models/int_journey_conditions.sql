SELECT
    jny_id,
    condition_code AS primary_condition_code,
    diagnosis AS primary_diagnosis,
    cond_start_date,
    cond_end_date,
    condition_type
FROM (
    SELECT
        ej.jny_id,
        ej.jny_seq_no,
        c.cond_start_date,
        c.cond_end_date,
        c.condition_type,
        c.condition_code,
        COALESCE(c.condition_name, 'No diagnosis') AS diagnosis,
        ROW_NUMBER() OVER (PARTITION BY ej.jny_id ORDER BY c.cond_start_date, c.condition_code ASC NULLS LAST) AS row_num
    FROM {{ ref('s_encounter_journeys') }} ej
    LEFT JOIN {{ ref('s_conditions') }} c
        ON ej.enc_id = c.enc_id
        AND LOWER(c.condition_name) NOT LIKE '%(finding)%'
        AND LOWER(c.condition_name) NOT LIKE '%(situation)%'
        AND LOWER(c.condition_name) <> 'normal pregnancy'
) sub
WHERE row_num = 1