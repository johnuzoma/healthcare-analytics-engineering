 {% macro get_journey_status(primary_condition_code, cond_end_date) %}
    CASE
        WHEN {{ primary_condition_code }} IS NULL OR {{ cond_end_date }} IS NOT NULL THEN 'Completed'
        ELSE 'Ongoing'
    END
{% endmacro %}