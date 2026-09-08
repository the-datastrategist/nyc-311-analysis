{% macro prepare_bqml_fact_table(fct_relation, columns_ddl, model_id) %}
  {#-
    Prepares an ml_fct_* table for a fresh insert: creates it if missing,
    ensures it has a model_run_id column (for tables created before that
    column existed), and deletes any existing rows for model_id so a rerun
    replaces that model's rows instead of accumulating duplicates.

    Args:
        fct_relation: The Relation of the ml_fct_* table to write to
        columns_ddl: String of the table's column definitions (without the
            enclosing parentheses), used only when the table doesn't exist yet
        model_id: Identifier of the model whose previous rows should be cleared
  -#}

  {%- set create_table_sql -%}
create table if not exists {{ fct_relation }} (
{{ columns_ddl }}
)
  {%- endset -%}
  {% do run_query(create_table_sql) %}

  {%- set add_column_sql -%}
alter table {{ fct_relation }} add column if not exists model_run_id string
  {%- endset -%}
  {% do run_query(add_column_sql) %}

  {%- set delete_sql -%}
delete from {{ fct_relation }} where model_id = '{{ model_id }}'
  {%- endset -%}
  {% do run_query(delete_sql) %}
{% endmacro %}
