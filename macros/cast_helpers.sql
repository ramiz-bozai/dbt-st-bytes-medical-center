{% macro cast_to_double(column_name) %}
    try_cast({{ column_name }} as double)
{% endmacro %}

{% macro cast_to_timestamp(column_name) %}
    try_cast({{ column_name }} as timestamp)
{% endmacro %}

{% macro cast_to_date(column_name) %}
    try_cast(cast({{ column_name }} as string) as date)
{% endmacro %}

{% macro cast_unix_day_to_date(column_name) %}
    case
        when {{ column_name }} is null then null
        else date_from_unix_date(cast({{ column_name }} as int))
    end
{% endmacro %}
