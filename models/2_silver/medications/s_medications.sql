WITH transformed_meds AS (
    SELECT
        CAST(start_date_time AS DATE) AS med_start_date,
        DATE_FORMAT(start_date_time, 'HH:mm:ss') AS med_start_time,
        CAST(end_date_time AS DATE) AS med_end_date,
        DATE_FORMAT(end_date_time, 'HH:mm:ss') AS med_end_time,
        patient_id,
        payer_id,
        encounter_id,
        code,
        description AS med_description,
        base_cost,
        payer_coverage,
        dispenses,
        total_cost,
        reason,

        DATEDIFF(
            DAY,
            LAG(end_date_time) OVER (PARTITION BY patient_id, code ORDER BY start_date_time),
            start_date_time
        ) AS days_since_last_fill_ended,
        DATEDIFF(DAY, start_date_time, end_date_time) AS days_supply,

        CASE WHEN end_date_time IS NULL THEN 'Ongoing' ELSE 'Completed' END AS med_status,

        CASE 
            WHEN ROW_NUMBER() OVER (PARTITION BY patient_id, code ORDER BY start_date_time) > 1 THEN 'Refill' 
            ELSE 'Initial' 
        END AS fill_type
    FROM {{ ref('b_medications') }}    
),

encounters AS (
    SELECT
        id,
        INITCAP(encounter_class) AS encounter_class
    FROM {{ ref('b_encounters') }}
),

enhancements AS (
    SELECT
        meds.*,

        encounters.encounter_class,

        (meds.total_cost - meds.payer_coverage) AS patient_responsibility,

        meds.payer_coverage / meds.total_cost AS coverage_ratio,

        AVG(meds.total_cost) OVER (PARTITION BY meds.code) AS avg_cost_per_drug,

        STDDEV(meds.total_cost) OVER (PARTITION BY meds.code) AS stddev_cost_per_drug
    FROM transformed_meds meds
    LEFT JOIN encounters
        ON meds.encounter_id = encounters.id
),

final_enhancements AS (
    SELECT
        *,
        CASE
            WHEN days_since_last_fill_ended > 0 THEN 'Gap'
            WHEN days_since_last_fill_ended < 0 THEN 'Overlap'
            ELSE 'Continuous'
        END AS adherence_flag,
        CASE
            WHEN stddev_cost_per_drug = 0 THEN 'No Variance'
            WHEN (total_cost - avg_cost_per_drug) / NULLIF(stddev_cost_per_drug, 0) > 2 THEN 'High Cost Outlier' -- cost is more than 2 standard deviations above the drug's average
            WHEN (total_cost - avg_cost_per_drug) / NULLIF(stddev_cost_per_drug, 0) < -2 THEN 'Low Cost Outlier' -- cost is more than 2 standard deviations below the drug's average
            ELSE 'Normal'
        END AS cost_outlier_flag
    FROM enhancements
)

SELECT * FROM final_enhancements