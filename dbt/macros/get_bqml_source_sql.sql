{% macro get_bqml_source_sql(model_config, split) %}
  {#-
    Macro to fetch a named source_sql query from a model_config's data block.

    The returned string is rendered through Jinja, so source_sql in
    dbt_project.yml can reference {{ var(...) }} (e.g. an optional cutoff
    date with a default) or {{ ref(...) }} instead of only static SQL.

    Args:
        model_config: Dictionary containing model configuration from dbt_project.yml
        split: One of 'train', 'validation', 'test' -- the data.<split>.source_sql to fetch

    Returns:
        String containing the rendered SQL defined at model_config.data.<split>.source_sql
  -#}

  {%- if model_config.data is not defined
        or model_config.data.get(split) is none
        or model_config.data[split].source_sql is not defined -%}
    {{ exceptions.raise_compiler_error(
        "No data." ~ split ~ ".source_sql defined for model_config: " ~ model_config.model_name
    ) }}
  {%- endif -%}

  {{ return(render(model_config.data[split].source_sql)) }}
{% endmacro %}
