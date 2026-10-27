{% macro replace_with_not_given(col_or_expr) %}
    COALESCE(NULLIF({{ col_or_expr }}, ''), 'Not Given')
{% endmacro %}