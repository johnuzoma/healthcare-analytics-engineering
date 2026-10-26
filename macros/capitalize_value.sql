{% macro capitalize_value(col_or_expr) %}
    INITCAP({{ col_or_expr }})
{% endmacro %}