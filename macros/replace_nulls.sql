{% macro replace_nulls(col_or_expr) %}
    COALESCE(NULLIF({{ col_or_expr }}, ''), 'Not Given')
{% endmacro %}