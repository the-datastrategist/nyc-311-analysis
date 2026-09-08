{% macro get_bqml_model_options(model_config) %}
  {#-
    Macro to generate the OPTIONS(...) clause for a BQML CREATE MODEL statement.

    Args:
        model_config: Dictionary containing model configuration from dbt_project.yml

    Returns:
        String of comma-separated OPTIONS entries formatted for a BQML OPTIONS() clause
  -#}

  {%- set options = [] -%}
  {%- set _ = options.append("MODEL_TYPE = '" ~ model_config.model_type ~ "'") -%}

  {%- if model_config.input_label_cols is defined -%}
    {%- set label_list = [] -%}
    {%- for col in model_config.input_label_cols -%}
      {%- set _ = label_list.append("'" ~ col ~ "'") -%}
    {%- endfor -%}
    {%- set _ = options.append("INPUT_LABEL_COLS = [" ~ (label_list | join(', ')) ~ "]") -%}
  {%- endif -%}

  {%- for key, value in (model_config.parameters or {}).items() -%}
    {%- set option_key = key | upper -%}
    {%- if value is sameas true -%}
      {%- set _ = options.append(option_key ~ " = TRUE") -%}
    {%- elif value is sameas false -%}
      {%- set _ = options.append(option_key ~ " = FALSE") -%}
    {%- elif value is number -%}
      {%- set _ = options.append(option_key ~ " = " ~ value) -%}
    {%- else -%}
      {%- set _ = options.append(option_key ~ " = '" ~ value ~ "'") -%}
    {%- endif -%}
  {%- endfor -%}

  {{ return(options | join(",\n    ")) }}
{% endmacro %}
