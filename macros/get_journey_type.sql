 {% macro get_journey_type(condition_type, total_wellness, total_encounters, total_ip_admissions, total_procedures) %}
    CASE
        WHEN {{ condition_type }} IS NOT NULL THEN {{ condition_type }}
        WHEN {{ total_wellness }} = {{ total_encounters }} THEN 'Preventive'
        WHEN {{ total_ip_admissions }} > 0 AND COALESCE({{ total_procedures }}, 0) > 0 THEN 'Surgical'
        ELSE 'Unclassified'
    END
{% endmacro %}