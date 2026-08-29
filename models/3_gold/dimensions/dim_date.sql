WITH date_spine AS (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="CAST('1900-01-01' AS DATE)",
        end_date="CURRENT_DATE()"
    ) }}
)

, enhancements AS (
    SELECT
        date_day AS date,
        YEAR(date_day) AS year,
        CONCAT('Q', QUARTER(date_day)) AS quarter,
        CONCAT('Q', QUARTER(date_day), " '", DATE_FORMAT(date_day, 'yy')) AS quarter_year,
        DATE_FORMAT(date_day, 'MMM') AS month,
        CONCAT(DATE_FORMAT(date_day, 'MMM'), " '", DATE_FORMAT(date_day, 'yy')) AS month_year,
        CONCAT('Wk', " ", WEEKOFYEAR(date_day), " '", DATE_FORMAT(date_day, 'yy')) AS week_year,

        -- sort keys
        YEAR(date_day) * 10 + QUARTER(date_day) AS year_quarter_number,
        YEAR(date_day) * 100 + MONTH(date_day) AS year_month_number,
        YEAR(date_day) * 100 + WEEKOFYEAR(date_day) AS year_week_number
    FROM date_spine
)

SELECT * FROM enhancements