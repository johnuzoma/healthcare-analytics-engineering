SELECT
    jny_id,
    jny_seq_no,
    patient_id,
    MIN(enc_start_date) AS jny_start_date,
    MAX(enc_end_date) AS jny_end_date,
    COUNT(*) AS total_encounters,
    COUNT_IF(enc_class = 'Inpatient') AS total_ip_admissions,
    COUNT_IF(enc_class = 'Wellness') AS total_wellness,
    MIN_BY(enc_class, enc_start_ts) AS entry_point,
    ARRAY_JOIN(
        TRANSFORM(ARRAY_SORT(COLLECT_LIST(STRUCT(enc_start_ts, enc_class))), x -> x.enc_class),
        ' > '
    ) AS path_signature
FROM {{ ref('s_encounter_journeys') }}
GROUP BY jny_id, jny_seq_no, patient_id