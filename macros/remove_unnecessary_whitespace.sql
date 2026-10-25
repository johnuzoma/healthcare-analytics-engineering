{% macro remove_unnecessary_whitespace(col_or_expr) %}
    -- TRIM removes leading and trailing whitespace, and REGEXP_REPLACE replaces 2 or more internal spaces with a single space
    TRIM(
        REGEXP_REPLACE(
            {{ col_or_expr }}, ' {2,}', ' '
        )
    )
{% endmacro %}