{% macro run_bqml_pipeline(model_name=none, lifecycle=none, steps='train,validate,predict') %}
  {#-
    Runs the BQML train/validate/predict pipeline for one or more models
    defined in model_configs (see dbt_project.yml). Each step still respects
    that model_config's own include_in_run / include_in_forecast flags.

    Usage:
        dbt run-operation run_bqml_pipeline
        dbt run-operation run_bqml_pipeline --args '{model_name: next_day_requests_xgboost}'
        dbt run-operation run_bqml_pipeline --args '{lifecycle: prod}'
        dbt run-operation run_bqml_pipeline --args '{steps: "train,validate"}'

    Args:
        model_name: Optional. Run the pipeline for only this model_name. If
            omitted, runs for every entry in model_configs.
        lifecycle: Optional. Only run for models with this `lifecycle` value
            (e.g. 'prod'). If omitted, runs for models of any lifecycle.
        steps: Optional. Comma-separated subset of 'train', 'validate',
            'predict' to run. Defaults to all three.
  -#}

  {%- set model_configs = var('model_configs', []) -%}
  {%- set selected_steps = steps.split(',') | map('trim') | list -%}
  {%- set ns = namespace(matched=false) -%}

  {%- for cfg in model_configs -%}
    {%- if (model_name is none or cfg.model_name == model_name)
          and (lifecycle is none or cfg.lifecycle == lifecycle) -%}
      {%- set ns.matched = true -%}

      {{ log("=== BQML pipeline: " ~ cfg.model_name ~ " (steps: " ~ (selected_steps | join(', ')) ~ ") ===", info=true) }}

      {%- if 'train' in selected_steps -%}
        {% do train_bqml_model(cfg.model_name) %}
      {%- endif -%}

      {%- if 'validate' in selected_steps -%}
        {% do validate_bqml_model(cfg.model_name) %}
      {%- endif -%}

      {%- if 'predict' in selected_steps -%}
        {% do predict_bqml_model(cfg.model_name) %}
      {%- endif -%}
    {%- endif -%}
  {%- endfor -%}

  {%- if not ns.matched -%}
    {{ exceptions.raise_compiler_error(
        "No model_configs matched model_name=" ~ model_name ~ ", lifecycle=" ~ lifecycle
    ) }}
  {%- endif -%}

  {{ log("Finished BQML pipeline run.", info=true) }}
{% endmacro %}
