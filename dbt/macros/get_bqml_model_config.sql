{% macro get_bqml_model_config(model_name) %}
  {#-
    Macro to look up a single entry from the model_configs var by model_name.

    Args:
        model_name: The `model_name` of the entry to find, as defined under
            model_configs in dbt_project.yml

    Returns:
        Dictionary containing the matching model_config entry
  -#}

  {%- set model_configs = var('model_configs', []) -%}
  {%- set ns = namespace(model_config=none) -%}
  {%- for cfg in model_configs -%}
    {%- if cfg.model_name == model_name -%}
      {%- set ns.model_config = cfg -%}
    {%- endif -%}
  {%- endfor -%}

  {%- if ns.model_config is none -%}
    {{ exceptions.raise_compiler_error("No model_config found in model_configs for model_name: " ~ model_name) }}
  {%- endif -%}

  {{ return(ns.model_config) }}
{% endmacro %}


{% macro get_bqml_model_id(model_config) %}
  {#-
    Macro to build the BQML model identifier for a model_config.

    Replaces '.' with '_' since BigQuery treats a bare '.' inside a
    backtick-quoted identifier as a path separator.

    Args:
        model_config: Dictionary containing model configuration from dbt_project.yml

    Returns:
        String containing the sanitized model identifier (name ~ version)
  -#}

  {{ return(model_config.model_name ~ '_' ~ (model_config.version | replace('.', '_'))) }}
{% endmacro %}


{% macro get_bqml_model_relation_sql(model_id) %}
  {#-
    Macro to build a fully-qualified, backtick-quoted BQML model reference
    in the current dbt target's project/dataset.

    Args:
        model_id: The model identifier (see get_bqml_model_id)

    Returns:
        String containing the backtick-quoted `project`.`dataset`.`model_id` reference
  -#}

  {{ return('`' ~ target.database ~ '`.`' ~ target.schema ~ '`.`' ~ model_id ~ '`') }}
{% endmacro %}


{% macro should_run_bqml_step(model_config, flag_key, step_label, model_name) %}
  {#-
    Macro to check a model_config's include_in_run / include_in_forecast
    flag before running a pipeline step, logging a skip message when false.

    Args:
        model_config: Dictionary containing model configuration from dbt_project.yml
        flag_key: The model_config key to check (e.g. 'include_in_run')
        step_label: Human-readable step name for the skip log message (e.g. 'training')
        model_name: The model_name being evaluated, for the skip log message

    Returns:
        Boolean: True if the step should run, False if it should be skipped
  -#}

  {%- if not model_config.get(flag_key, true) -%}
    {{ log("Skipping " ~ step_label ~ " for " ~ model_name ~ ": " ~ flag_key ~ " is false", info=true) }}
    {{ return(false) }}
  {%- else -%}
    {{ return(true) }}
  {%- endif -%}
{% endmacro %}
