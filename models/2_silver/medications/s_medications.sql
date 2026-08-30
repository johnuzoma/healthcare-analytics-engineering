WITH transformed_meds AS (
    SELECT
        CAST(START AS DATE) AS med_start_date,
        DATE_FORMAT(START, 'HH:mm:ss') AS med_start_time,
        CAST(STOP AS DATE) AS med_end_date,
        DATE_FORMAT(STOP, 'HH:mm:ss') AS med_end_time,
        PATIENT AS patient_id,
        PAYER AS payer_id,
        ENCOUNTER AS encounter_id,
        CODE AS code,
        DESCRIPTION AS med_description,
        BASE_COST AS base_cost,
        PAYER_COVERAGE AS payer_coverage,
        DISPENSES AS dispenses,
        TOTALCOST AS total_cost,
        TOTALCOST / DISPENSES AS cost_per_dispenses,
        REASONCODE AS reason_code,
        REASONDESCRIPTION AS reason,

        DATEDIFF(
            DAY,
            LAG(STOP) OVER (PARTITION BY PATIENT, CODE ORDER BY START),
            START
        ) AS days_since_last_fill_ended,
        DATEDIFF(DAY, START, STOP) AS days_supply,

        CASE WHEN STOP IS NULL THEN 'Ongoing' ELSE 'Completed' END AS med_status,

        CASE 
            WHEN ROW_NUMBER() OVER (PARTITION BY PATIENT, CODE ORDER BY START) > 1 THEN 'Refill' 
            ELSE 'Initial' 
        END AS fill_type
    FROM {{ source('bronze', 'medications') }}    
),

encounters AS (
    SELECT
        Id AS id,
        INITCAP(ENCOUNTERCLASS) AS encounter_class
    FROM {{ source('bronze', 'encounters') }}
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