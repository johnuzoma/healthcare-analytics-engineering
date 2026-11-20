WITH transformed_meds AS (
    SELECT
        start AS med_start_ts,
        CAST(start AS DATE) AS med_start_date,
        DATE_FORMAT(start, 'HH:mm:ss') AS med_start_time,
        stop AS med_end_ts,
        CAST(stop AS DATE) AS med_end_date,
        DATE_FORMAT(stop, 'HH:mm:ss') AS med_end_time,
        patient AS patient_id,
        payer AS payer_id,
        encounter AS enc_id,
        CAST(code AS STRING) AS code,
        {{ capitalize_value('description') }} AS med_description,
        base_cost AS med_base_cost,
        payer_coverage AS med_payer_coverage,
        dispenses,
        totalcost AS med_total_cost,
        CAST(reasoncode AS STRING) AS reason_code,
        reasondescription AS med_reason,

        DATEDIFF(
            DAY,
            LAG(stop) OVER (PARTITION BY patient, code ORDER BY start),
            start
        ) AS days_since_last_fill_ended,

        DATEDIFF(DAY, start, stop) AS days_supply,

        CASE
            WHEN stop IS NULL THEN 'Ongoing'
            ELSE 'Completed'
        END AS med_status,

        CASE
            WHEN ROW_NUMBER() OVER (PARTITION BY patient, code ORDER BY start) > 1 THEN 'Refill'
            ELSE 'Initial'
        END AS fill_type
    FROM {{ source('bronze', 'medications') }}
    WHERE start <= stop
),

encounters AS (
    SELECT
        id,
        INITCAP(encounterclass) AS encounter_class
    FROM {{ source('bronze', 'encounters') }}
),

enhancements AS (
    SELECT
        meds.*,

        encounters.encounter_class,

        (meds.med_total_cost - meds.med_payer_coverage) AS med_patient_responsibility,

        meds.med_payer_coverage / meds.med_total_cost AS coverage_ratio,

        AVG(meds.med_total_cost) OVER (PARTITION BY meds.code) AS avg_cost_per_drug,

        STDDEV(meds.med_total_cost) OVER (PARTITION BY meds.code) AS stddev_cost_per_drug
    FROM transformed_meds meds
    LEFT JOIN encounters
        ON meds.enc_id = encounters.id
),

final_enhancements AS (
    SELECT
        *,
        CASE
            WHEN days_since_last_fill_ended > 0 THEN 'Gap'
            WHEN days_since_last_fill_ended < 0 THEN 'Overlap'
            WHEN days_since_last_fill_ended = 0 THEN 'Continuous'
            ELSE 'NA'
        END AS adherence_flag,

        CASE
            WHEN stddev_cost_per_drug = 0 THEN 'No Variance'
            WHEN (med_total_cost - avg_cost_per_drug) / NULLIF(stddev_cost_per_drug, 0) > 2 THEN 'High'
            WHEN (med_total_cost - avg_cost_per_drug) / NULLIF(stddev_cost_per_drug, 0) < -2 THEN 'Low'
            ELSE 'Normal'
        END AS cost_outlier_flag
    FROM enhancements
)

SELECT *
FROM final_enhancements