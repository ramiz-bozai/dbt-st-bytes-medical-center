{% macro stream_read_synthea_csv(csv_filename) %}
from stream read_files(
    '{{ var("synthea_volume_path") }}',
    format => 'csv',
    header => true,
    pathGlobFilter => '{{ csv_filename }}'
)
{% endmacro %}
