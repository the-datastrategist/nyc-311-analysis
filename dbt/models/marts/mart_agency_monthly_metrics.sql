{{ config(materialized='table') }}

with

agency_daily_metrics as (
  select
    agency_code,
    asof_date,
    holiday_name,
    requests,
    complaint_types
  from {{ ref('int_agency_daily_metrics') }}
),

daily_metrics as (
  select
    asof_date,
    sum(requests) as nyc_requests
  from agency_daily_metrics
  group by 1
),

agency_monthly_metrics as (
  select
    date_trunc(asof_date, month) as asof_month,
    agency_code,
    max(holiday_name) as holiday_name,  -- TODO: improve logic
    count(distinct asof_date) as request_days,
    sum(requests) as requests
  from agency_daily_metrics
  group by 1,2
),

monthly_metrics as (
  select
    date_trunc(asof_date, month) as asof_month,
    count(distinct asof_date) as nyc_request_days,
    sum(requests) as nyc_requests
  from agency_daily_metrics
  group by 1
),

joined_monthly_metrics as (
    select
        amm.*,
        mm.nyc_requests,
        safe_divide(request_days, mm.nyc_request_days) as pct_nyc_request_days,
        safe_divide(requests, mm.nyc_requests) as pct_nyc_requests
    from agency_monthly_metrics amm
    join monthly_metrics mm using (asof_month)
),

service_requests_metrics as (
  select
    *,

    sum(requests) over (partition by agency_code order by asof_month rows between 1 following and 1 following)  as requests_next_1month,
    sum(requests) over (partition by agency_code order by asof_month rows between 1 following and 12 following) as requests_next_12month,

    -- Total Rolling Requests
    sum(requests) over (partition by agency_code order by asof_month rows between 2 preceding and current row)  as requests_last_3month,
    sum(requests) over (partition by agency_code order by asof_month rows between 5 preceding and current row)  as requests_last_6month,
    sum(requests) over (partition by agency_code order by asof_month rows between 11 preceding and current row) as requests_last_12month,

    -- Avg Rolling Requests
    avg(requests) over (partition by agency_code order by asof_month rows between 2 preceding and current row)  as avg_requests_last_3month,
    avg(requests) over (partition by agency_code order by asof_month rows between 5 preceding and current row)  as avg_requests_last_6month,
    avg(requests) over (partition by agency_code order by asof_month rows between 11 preceding and current row) as avg_requests_last_12month,

    -- Total Rolling Requests (previous period)
    avg(requests) over (partition by agency_code order by asof_month rows between 5 preceding and 3 preceding)   as avg_requests_prev_3month,
    avg(requests) over (partition by agency_code order by asof_month rows between 11 preceding and 6 preceding)  as avg_requests_prev_6month,
    avg(requests) over (partition by agency_code order by asof_month rows between 23 preceding and 12 preceding) as avg_requests_prev_12month,

  from joined_monthly_metrics
)

select *
from service_requests_metrics
order by agency_code, asof_month
