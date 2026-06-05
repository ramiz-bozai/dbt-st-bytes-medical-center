{% macro query_comment_json(extra={}) %}
    {%- set payload = {
        'project': project_name,
        'target': target.name,
        'node': model.name if model else 'unknown',
        'resource': model.resource_type if model else 'unknown',
        'layer': model.config.get('meta', {}).get('layer', 'unset') if model else 'unset',
    } -%}
    {%- do payload.update(extra) -%}
    {{ return(tojson(payload)) }}
{% endmacro %}
