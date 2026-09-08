{% macro log_bqml_training_metadata(model_config, model_id) %}
  {#-
    Logs metadata about a BQML training run to the ml_fct_train table.

    Consolidates ML.TRAINING_INFO()'s per-iteration rows for the model into a
    single summary row per model_run_id: one finalized, trained model per
    model config per CLI run. The raw per-iteration rows are kept as a JSON
    array (training_info) since their columns can differ across BQML model
    types.

    Args:
        model_config: Dictionary containing model configuration from dbt_project.yml
        model_id: Identifier of the model that was just trained (name ~ version)
  -#}

  {%- set fct_relation = api.Relation.create(database=target.database, schema=target.schema, identifier='ml_fct_train') -%}
  {%- set model_relation_sql = get_bqml_model_relation_sql(model_id) -%}

  {%- set columns_ddl -%}
  model_run_id string,
  model_name string,
  model_version string,
  model_id string,
  model_type string,
  lifecycle string,
  model_interval string,
  label_columns string,
  parameters string,
  iteration_count int64,
  training_info string,
  trained_at timestamp
  {%- endset -%}
  {% do prepare_bqml_fact_table(fct_relation, columns_ddl, model_id) %}

  {%- set migrate_columns_sql -%}
alter table {{ fct_relation }}
  add column if not exists iteration_count int64,
  add column if not exists training_info string
  {%- endset -%}
  {% do run_query(migrate_columns_sql) %}

  {%- set label_columns_json = (tojson(model_config.input_label_cols if model_config.input_label_cols is defined else [])) | replace("'", "\\'") -%}
  {%- set parameters_json = (tojson(model_config.parameters if model_config.parameters is defined else {})) | replace("'", "\\'") -%}

  {%- set insert_sql -%}
insert into {{ fct_relation }} (
  model_run_id, model_name, model_version, model_id, model_type, lifecycle, model_interval,
  label_columns, parameters,
  iteration_count, training_info, trained_at
)
with info as (
  select *
  from ml.training_info(model {{ model_relation_sql }})
)
select
  '{{ invocation_id }}' as model_run_id,
  '{{ model_config.model_name }}' as model_name,
  '{{ model_config.version }}' as model_version,
  '{{ model_id }}' as model_id,
  '{{ model_config.model_type }}' as model_type,
  '{{ model_config.lifecycle }}' as lifecycle,
  '{{ model_config.interval }}' as model_interval,
  '{{ label_columns_json }}' as label_columns,
  '{{ parameters_json }}' as parameters,
  (select count(*) from info) as iteration_count,
  (select to_json_string(array_agg(info)) from info) as training_info,
  current_timestamp() as trained_at
  {%- endset -%}
  {% do run_query(insert_sql) %}

  {{ log("Logged training metadata for " ~ model_id ~ " to " ~ fct_relation, info=true) }}
{% endmacro %}
