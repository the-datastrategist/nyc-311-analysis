{% macro validate_bqml_model(model_name) %}
  {#-
    Validates a trained BQML model and logs the resulting ML.EVALUATE metrics
    to the ml_fct_validate table.

    Usage:
        dbt run-operation validate_bqml_model --args '{model_name: next_day_requests_xgboost}'

    Args:
        model_name: The `model_name` of the entry to validate, as defined under
            model_configs in dbt_project.yml
  -#}

  {%- set model_config = get_bqml_model_config(model_name) -%}

  {%- if should_run_bqml_step(model_config, 'include_in_run', 'validation', model_name) -%}
    {%- set model_id = get_bqml_model_id(model_config) -%}
    {%- set model_relation_sql = get_bqml_model_relation_sql(model_id) -%}
    {%- set fct_relation = api.Relation.create(database=target.database, schema=target.schema, identifier='ml_fct_validate') -%}

    {%- if model_config.data is defined
          and model_config.data.get('validation') is not none
          and model_config.data.validation.source_sql is defined -%}
      {%- set validation_sql = get_bqml_source_sql(model_config, 'validation') -%}
      {%- set evaluate_source_sql -%}
ml.evaluate(model {{ model_relation_sql }}, (
{{ validation_sql }}
))
      {%- endset -%}
    {%- else -%}
      {%- set evaluate_source_sql -%}
ml.evaluate(model {{ model_relation_sql }})
      {%- endset -%}
    {%- endif -%}

    {%- set columns_ddl -%}
  model_run_id string,
  model_name string,
  model_version string,
  model_id string,
  model_type string,
  metrics string,
  evaluated_at timestamp
    {%- endset -%}
    {% do prepare_bqml_fact_table(fct_relation, columns_ddl, model_id) %}

    {%- set insert_sql -%}
insert into {{ fct_relation }} (
  model_run_id, model_name, model_version, model_id, model_type, metrics, evaluated_at
)
select
  '{{ invocation_id }}' as model_run_id,
  '{{ model_config.model_name }}' as model_name,
  '{{ model_config.version }}' as model_version,
  '{{ model_id }}' as model_id,
  '{{ model_config.model_type }}' as model_type,
  to_json_string(eval_result) as metrics,
  current_timestamp() as evaluated_at
from {{ evaluate_source_sql }} as eval_result
    {%- endset -%}

    {{ log("Validating BQML model: " ~ model_id, info=true) }}
    {% do run_query(insert_sql) %}

    {{ log("Logged validation metrics for " ~ model_id ~ " to " ~ fct_relation, info=true) }}
  {%- endif -%}
{% endmacro %}
