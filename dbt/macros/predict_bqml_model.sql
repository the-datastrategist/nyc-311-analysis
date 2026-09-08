{% macro predict_bqml_model(model_name) %}
  {#-
    Generates a prediction for each record in a model's data.predict.source_sql
    query (see model_configs in dbt_project.yml) using ML.PREDICT against the
    trained BQML model. 

    Usage:
        dbt run-operation predict_bqml_model --args '{model_name: next_day_requests_xgboost}'

    Args:
        model_name: The `model_name` of the entry to predict with, as defined
            under model_configs in dbt_project.yml
  -#}

  {%- set model_config = get_bqml_model_config(model_name) -%}

  {%- if should_run_bqml_step(model_config, 'include_in_forecast', 'prediction', model_name) -%}
    {%- set model_id = get_bqml_model_id(model_config) -%}
    {%- set model_relation_sql = get_bqml_model_relation_sql(model_id) -%}

    {%- if model_config.data is not defined or model_config.data.get('predict') is none -%}
      {{ exceptions.raise_compiler_error("No data.predict block defined for model_config: " ~ model_name) }}
    {%- endif -%}
    {%- set predict_config = model_config.data.predict -%}

    {%- if predict_config.outcome_field is not defined -%}
      {{ exceptions.raise_compiler_error("No data.predict.outcome_field defined for model_config: " ~ model_name) }}
    {%- endif -%}
    {%- if predict_config.id_fields is not defined -%}
      {{ exceptions.raise_compiler_error("No data.predict.id_fields defined for model_config: " ~ model_name) }}
    {%- endif -%}

    {%- set output_table = predict_config.output_table if predict_config.output_table is defined else 'predictions_' ~ model_id -%}
    {%- set predictions_relation = api.Relation.create(database=target.database, schema=target.schema, identifier=output_table) -%}
    {%- set predict_sql = get_bqml_source_sql(model_config, 'predict') -%}

    {%- set select_parts = predict_config.id_fields + [predict_config.outcome_field] -%}

    {%- set create_predictions_sql -%}
create or replace table {{ predictions_relation }} as
select
  {{ select_parts | join(",\n  ") }},
  '{{ invocation_id }}' as model_run_id,
  '{{ model_config.model_name }}' as model_name,
  '{{ model_config.version }}' as model_version,
  '{{ model_id }}' as model_id,
  '{{ model_config.model_type }}' as model_type,
  current_timestamp() as predicted_at
from ml.predict(model {{ model_relation_sql }}, (
{{ predict_sql }}
))
    {%- endset -%}

    {{ log("Predicting with BQML model: " ~ model_id, info=true) }}
    {% do run_query(create_predictions_sql) %}

    {{ log("Wrote predictions for " ~ model_id ~ " to " ~ predictions_relation, info=true) }}
  {%- endif -%}
{% endmacro %}
