{{ config(materialized='view') }}

SELECT MAX(CAST(start AS DATE)) AS as_of_date FROM {{ source('bronze', 'encounters') }}