{{ config(materialized='table') }}

with

daily_metrics as (
  select
    asof_date,
    asof_month,
    asof_year,
    agency_code,
    holiday_name,
    requests
  from {{ ref('int_agency_daily_metrics') }}
),

monthly_metrics as (
  select
    date_trunc(asof_date, month) as asof_month_date,
    max(asof_month)              as asof_month,
    max(asof_year)               as asof_year,
    count(distinct agency_code)  as agency_count,
    count(distinct holiday_name) as holiday_count,
    count(distinct asof_date)    as request_days,
    sum(requests)                as requests
  from daily_metrics
  group by 1
),

service_requests_metrics as (
  select
    *,
    
    sum(requests) over (order by asof_month_date rows between 1 following and 1 following)  as requests_next_1month,
    sum(requests) over (order by asof_month_date rows between 1 following and 12 following) as requests_next_12month,

    -- Total Rolling Requests
    sum(requests) over (order by asof_month_date rows between 2 preceding and current row)  as requests_last_3month,
    sum(requests) over (order by asof_month_date rows between 5 preceding and current row)  as requests_last_6month,
    sum(requests) over (order by asof_month_date rows between 11 preceding and current row) as requests_last_12month,

    -- Total Rolling Requests (previous period)
    avg(requests) over (order by asof_month_date rows between 5 preceding and 3 preceding)   as avg_requests_prev_3month,
    avg(requests) over (order by asof_month_date rows between 11 preceding and 6 preceding)  as avg_requests_prev_6month,
    avg(requests) over (order by asof_month_date rows between 23 preceding and 12 preceding) as avg_requests_prev_12month,

  from monthly_metrics
)

select *
from service_requests_metrics
order by asof_month_date
