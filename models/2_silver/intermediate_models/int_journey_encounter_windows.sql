SELECT
    jny_id, patient_id, enc_id, provider_id, organization_id, payer_id, enc_start_date,
    LEAD(enc_start_date) OVER (PARTITION BY jny_id ORDER BY enc_start_ts, enc_id) AS next_jny_enc_date,
    LEAD(payer_id) OVER (PARTITION BY jny_id ORDER BY enc_start_ts, enc_id) AS next_jny_payer_id,
    LEAD(provider_id) OVER (PARTITION BY jny_id ORDER BY enc_start_ts, enc_id) AS next_jny_provider_id,
    LEAD(organization_id) OVER (PARTITION BY jny_id ORDER BY enc_start_ts, enc_id) AS next_jny_organization_id,
    LEAD(enc_start_date) OVER (PARTITION BY patient_id ORDER BY enc_start_ts, enc_id) AS next_patient_enc_date,
    LEAD(payer_id) OVER (PARTITION BY patient_id ORDER BY enc_start_ts, enc_id) AS next_patient_payer_id,
    LEAD(provider_id) OVER (PARTITION BY patient_id ORDER BY enc_start_ts, enc_id) AS next_patient_provider_id,
    LEAD(organization_id) OVER (PARTITION BY patient_id ORDER BY enc_start_ts, enc_id) AS next_patient_organization_id
FROM {{ ref('s_encounter_journeys') }}