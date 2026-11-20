SELECT
    ej.journey_seq_no,
    ej.enc_id,
    ej.patient_id,
    ej.provider_id,
    ej.organization_id,
    ej.payer_id,
    ej.enc_start_ts,
    ej.enc_start_date,
    ej.enc_start_time,
    ej.enc_end_ts,
    ej.enc_end_date,
    ej.enc_end_time,
    ej.enc_class,
    ej.enc_reason,
    ej.enc_description,
    ej.base_encounter_cost,
    ej.total_claim_cost,
    ej.payer_coverage,
    ej.patient_responsibility,
    ej.days_since_previous_encounter,
    
    -- allergies
    alg.alg_start_date,
    alg.alg_end_date,
    alg.alg_type,
    alg.alg_description,
    
    -- observations
    obs.obs_date_time,
    obs.obs_date,
    obs.obs_time,
    obs.obs_category,
    obs.obs_description,
    obs.obs_value,
    obs.obs_unit,

    -- conditions
    cond.cond_start_date,
    cond.cond_end_date,
    cond.condition_type,
    cond.condition_name,

    -- imaging_studies
    im.im_date_time,
    im.im_date,
    im.im_time,
    im.bodysite_description,
    im.sop_description,

    -- procedures
    pr.pr_start_date,
    pr.pr_start_time,
    pr.pr_end_date,
    pr.pr_end_time,
    pr.pr_description,
    pr.pr_reason,
    pr.pr_base_cost,

    -- immunizations
    imm.imm_date,
    imm.imm_time,
    imm.imm_description,
    imm.imm_base_cost,

    -- medications
    med.med_start_date,
    med.med_start_time,
    med.med_end_date,
    med.med_end_time,
    med.med_description,
    med.med_reason,
    med.med_base_cost,
    med.dispenses,
    med.med_total_cost,
    med.med_payer_coverage,
    med.med_patient_responsibility,

    -- careplans
    cp.cp_start_date,
    cp.cp_end_date,
    cp.cp_description,
    cp.cp_reason
FROM {{ ref('s_encounter_journeys') }} ej

LEFT JOIN {{ ref('s_allergies') }} alg
    ON ej.enc_id = alg.enc_id

LEFT JOIN {{ ref('s_observations') }} obs
    ON ej.enc_id = obs.enc_id

LEFT JOIN {{ ref('s_conditions') }} cond
    ON ej.enc_id = cond.enc_id

LEFT JOIN {{ ref('s_imaging_studies') }} im
    ON ej.enc_id = im.enc_id

LEFT JOIN {{ ref('s_procedures') }} pr
    ON ej.enc_id = pr.enc_id

LEFT JOIN {{ ref('s_immunizations') }} imm
    ON ej.enc_id = imm.enc_id

LEFT JOIN {{ ref('s_medications') }} med
    ON ej.enc_id = med.enc_id

LEFT JOIN {{ ref('s_careplans') }} cp
    ON ej.enc_id = cp.enc_id