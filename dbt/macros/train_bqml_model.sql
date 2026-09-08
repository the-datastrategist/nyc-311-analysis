{% macro train_bqml_model(model_name) %}
  {#-
    Trains a BQML model based on an entry in the `model_configs` var
    (see dbt_project.yml) and logs metadata about the training run to
    the ml_fct_train table.

    Usage:
        dbt run-operation train_bqml_model --args '{model_name: next_day_requests_xgboost}'

    Args:
        model_name: The `model_name` of the entry to train, as defined under
            model_configs in dbt_project.yml
  -#}

  {%- set model_config = get_bqml_model_config(model_name) -%}

  {%- if should_run_bqml_step(model_config, 'include_in_run', 'training', model_name) -%}
    {%- set model_id = get_bqml_model_id(model_config) -%}
    {%- set model_relation_sql = get_bqml_model_relation_sql(model_id) -%}
    {%- set options_sql = get_bqml_model_options(model_config) -%}
    {%- set train_sql = get_bqml_train_query(model_config) -%}

    {%- set create_model_sql -%}
create or replace model {{ model_relation_sql }}
options(
    {{ options_sql }}
)
as
{{ train_sql }}
    {%- endset -%}

    {{ log("Training BQML model: " ~ model_id, info=true) }}
    {% do run_query(create_model_sql) %}

    {{ log("Logging training metadata for " ~ model_id ~ " to ml_fct_train", info=true) }}
    {% do log_bqml_training_metadata(model_config, model_id) %}

    {{ log("Finished training " ~ model_id, info=true) }}
  {%- endif -%}
{% endmacro %}
