{{ config(materialized='view') }}

with

latest_predictions as (
  select * 
  from {{ source('ml', 'ml_agency_daily_predictions') }}
  qualify row_number() over (
    partition by agency_code, asof_date 
    order by predicted_at desc) = 1
),

daily_metrics as (
  select
    agency_code,
    asof_date,
    date_trunc(asof_date, week) as week_date,
    date_trunc(asof_date, month) as month_date,
    requests as requests_today,
    requests_next_1day as requests_tomorrow,
    avg_requests_last_28day_dow as baseline_today,
    lead(avg_requests_last_28day_dow, 1) over (
      partition by agency_code order by asof_date) as baseline_tomorrow,
  from {{ ref('int_agency_daily_metrics') }}
),

predictions_joined as (
  select
    lp.*,
    dm.week_date,
    dm.month_date,
    dm.requests_today,
    dm.baseline_today,
    lag(lp.predicted_requests_next_1day, 1) over (
      partition by lp.agency_code order by lp.asof_date) predicted_requests_today,
    lp.predicted_requests_next_1day as predicted_requests_tomorrow,
    dm.baseline_tomorrow,
    dm.requests_tomorrow
  from latest_predictions lp
  join daily_metrics dm
    on lp.agency_code = dm.agency_code
    and lp.asof_date = dm.asof_date
),

daily_metrics_w_error as (
  select *,

    -- Today Errors
    predicted_requests_today - requests_today as error_today,
    abs(predicted_requests_today - requests_today) as abs_error_today,
    safe_divide((predicted_requests_today - requests_today), requests_today) as pct_error_today,
    safe_divide(abs(predicted_requests_today - requests_today), requests_today) as abs_pct_error_today,
    
    -- Tomorrow Errors
    predicted_requests_tomorrow - requests_tomorrow as error_tomorrow,
    abs(predicted_requests_tomorrow - requests_tomorrow) as abs_error_tomorrow,
    safe_divide((predicted_requests_tomorrow - requests_tomorrow), requests_tomorrow) as pct_error_tomorrow,
    safe_divide(abs(predicted_requests_tomorrow - requests_tomorrow), requests_tomorrow) as abs_pct_error_tomorrow,
  
  from predictions_joined
)

select *
from daily_metrics_w_error
order by agency_code, asof_date
