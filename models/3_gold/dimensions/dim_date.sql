WITH date_spine AS (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="CAST('1913-01-01' AS DATE)",
        end_date="CURRENT_DATE()"
    ) }}
)

, enhancements AS (
    SELECT
        date_day AS date,
        YEAR(date_day) AS year,
        CONCAT('Q', QUARTER(date_day), "-", DATE_FORMAT(date_day, 'yyyy')) AS quarter_year,
        CONCAT(DATE_FORMAT(date_day, 'MMM'), "-", DATE_FORMAT(date_day, 'yyyy')) AS month_year,
        CONCAT('Wk', " ", WEEKOFYEAR(date_day), " ", EXTRACT(YEAROFWEEK FROM date_day)) AS week_year,

        -- sort keys
        YEAR(date_day) * 10 + QUARTER(date_day) AS year_quarter_number,
        YEAR(date_day) * 100 + MONTH(date_day) AS year_month_number,
        EXTRACT(YEAROFWEEK FROM date_day) * 100 + WEEKOFYEAR(date_day) AS year_week_number,

        -- flags
        CASE WHEN DAYOFWEEK(date_day) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
        CASE WHEN date_day > CURRENT_DATE() THEN 1 ELSE 0 END AS is_future
    FROM date_spine
)

SELECT * FROM enhancements