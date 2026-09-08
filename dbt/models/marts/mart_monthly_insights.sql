{{ config(materialized='table') }}
-- Referenced the following docs when building
-- https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-ai-generate

with

monthly_metrics as (
    select *
    from {{ ref('mart_monthly_metrics') }}
    where asof_year >= 2021 -- TODO: fix hardcoding
),

metrics_json as (
    select
        asof_month_date,
        to_json_string(struct(
            agency_count,
            holiday_count,
            request_days,

            requests,
            requests_next_1month,
            requests_next_12month,
            requests_last_3month,
            requests_last_6month,
            requests_last_12month,

            avg_requests_prev_3month,
            avg_requests_prev_6month,
            avg_requests_prev_12month
        )) as metrics_text
    from monthly_metrics
),

prompt as (
    select
        asof_month_date,
        concat(
            'You are a data analyst reviewing NYC 311 service request metrics for ',
            format_date('%B %Y', asof_month_date), '. ',
            'The JSON object below contains that month total requests, active agency count, ',
            'holiday count, forecasted next-period requests, and rolling averages for the ',
            'trailing and prior periods. ',
            'Analyze the data for seasonality, month-over-month trends, and anomalies, ',
            'then write a concise 2-3 sentence summary for this month.\n\n',
            metrics_text
        ) as prompt_text
    from metrics_json
)

select
    format_date('%Y-%m', asof_month_date) as insight_id,
    asof_month_date,
    current_timestamp() as generated_at,
    ai_response.result  as insight_summary,
    ai_response.full_response as full_response
from (
    select
        asof_month_date,
        ai.generate(
            prompt => prompt_text,
            connection_id => '{{ var("bq_ai_connection_id") }}',
            endpoint => '{{ var("bq_ai_endpoint") }}'
        ) as ai_response
    from prompt
)
order by asof_month_date
