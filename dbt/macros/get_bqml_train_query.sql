{% macro get_bqml_train_query(model_config) %}
  {#-
    Macro to generate the training SELECT statement used by a BQML CREATE MODEL AS query.

    Args:
        model_config: Dictionary containing model configuration from dbt_project.yml

    Returns:
        String containing the training SELECT statement
  -#}

  {%- if model_config.data is defined
        and model_config.data.train is defined
        and model_config.data.train.source_sql is defined -%}
    {{ return(model_config.data.train.source_sql) }}
  {%- endif -%}

  {%- set train_relation = ref(model_config.train_ref) -%}
  {%- set label_cols = model_config.input_label_cols if model_config.input_label_cols is defined else [] -%}
  {%- set feature_list = get_bqml_prediction_features(model_config) -%}
  {%- set select_parts = label_cols + [feature_list] -%}
  {%- set query -%}
select
  {{ select_parts | join(",\n  ") }}
from {{ train_relation }}
  {%- endset -%}

  {{ return(query) }}
{% endmacro %}
