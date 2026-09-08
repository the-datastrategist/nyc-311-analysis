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

agency_weekly_metrics as (
  select
    date_trunc(asof_date, week) as asof_week,
    agency_code,
    max(holiday_name) as holiday_name,  -- TODO: improve logic
    count(distinct asof_date) as request_days,
    sum(requests) as requests
  from agency_daily_metrics
  group by 1,2
),

weekly_metrics as (
  select
    date_trunc(asof_date, week) as asof_week,
    sum(requests) as nyc_requests
  from agency_daily_metrics
  group by 1
),

joined_weekly_metrics as (
select
  awm.*,
  wm.nyc_requests,
  safe_divide(requests, wm.nyc_requests) as pct_nyc_requests
from agency_weekly_metrics awm
join weekly_metrics wm using (asof_week)
),

service_requests_metrics as (
  select
    *,

    sum(requests) over (partition by agency_code order by asof_week rows between 1 following and 1 following) as requests_next_1week,
    sum(requests) over (partition by agency_code order by asof_week rows between 1 following and 4 following) as requests_next_4week,

    -- Total Rolling Requests
    sum(requests) over (partition by agency_code order by asof_week rows between 3 preceding and current row)  as requests_last_4week,
    sum(requests) over (partition by agency_code order by asof_week rows between 11 preceding and current row) as requests_last_12week,
    sum(requests) over (partition by agency_code order by asof_week rows between 27 preceding and current row) as requests_last_28week,
    sum(requests) over (partition by agency_code order by asof_week rows between 51 preceding and current row) as requests_last_52week,

    -- Avg Rolling Requests
    avg(requests) over (partition by agency_code order by asof_week rows between 3 preceding and current row)  as avg_requests_last_4week,
    avg(requests) over (partition by agency_code order by asof_week rows between 11 preceding and current row) as avg_requests_last_12week,
    avg(requests) over (partition by agency_code order by asof_week rows between 27 preceding and current row) as avg_requests_last_28week,
    avg(requests) over (partition by agency_code order by asof_week rows between 51 preceding and current row) as avg_requests_last_52week,

    -- Total Rolling Requests (previous period)
    avg(requests) over (partition by agency_code order by asof_week rows between 6 preceding and 3 preceding)   as avg_requests_prev_3day,
    avg(requests) over (partition by agency_code order by asof_week rows between 14 preceding and 7 preceding)  as avg_requests_prev_7day,
    avg(requests) over (partition by agency_code order by asof_week rows between 28 preceding and 14 preceding) as avg_requests_prev_14day,
    avg(requests) over (partition by agency_code order by asof_week rows between 56 preceding and 28 preceding) as avg_requests_prev_28day,

    avg(requests) over (partition by agency_code order by asof_week rows between 180 preceding and 90 preceding)  as avg_requests_prev_90day,
    avg(requests) over (partition by agency_code order by asof_week rows between 360 preceding and 180 preceding) as avg_requests_prev_180day,
    avg(requests) over (partition by agency_code order by asof_week rows between 730 preceding and 365 preceding) as avg_requests_prev_365day,

  from joined_weekly_metrics
)

select 
    *
from service_requests_metrics
order by agency_code, asof_week
