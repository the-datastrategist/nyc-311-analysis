{{ config(materialized='table') }}

with calendar as (
  select
    asof_date,
    holiday_name,
    is_holiday,
    postholiday_days,
    preholiday_days,
    days_since_holiday
  from {{ ref('int_calendar_holidays') }}
),

service_requests as (
  select
    date(created_date) as asof_date,
    agency_code,
    count(*) as requests,
    count(distinct complaint_type_normalized) as complaint_types
  from {{ ref('stg_service_requests') }}
  group by 1, 2
),

agencies as (
  select distinct agency_code
  from service_requests
  where agency_code is not null
),

service_requests_w_dates as (
  select
    a.agency_code,
    c.*,
    coalesce(r.requests, 0) as requests,
    coalesce(r.complaint_types, 0) as complaint_types
  from agencies a
  cross join calendar c
  left join service_requests r
    on a.agency_code = r.agency_code
   and c.asof_date = r.asof_date
),

service_requests_metrics as (
  select
    *,

    sum(requests) over (partition by agency_code order by asof_date rows between 1 following and 1 following) as requests_next_1day,
    sum(requests) over (partition by agency_code order by asof_date rows between 1 following and 7 following) as requests_next_7day,

    -- Total Rolling Requests
    sum(requests) over (partition by agency_code order by asof_date rows between 2 preceding and current row)  as requests_last_3day,
    sum(requests) over (partition by agency_code order by asof_date rows between 6 preceding and current row)  as requests_last_7day,
    sum(requests) over (partition by agency_code order by asof_date rows between 13 preceding and current row) as requests_last_14day,
    sum(requests) over (partition by agency_code order by asof_date rows between 27 preceding and current row) as requests_last_28day,

    sum(requests) over (partition by agency_code order by asof_date rows between 89 preceding and current row)  as requests_last_90day,
    sum(requests) over (partition by agency_code order by asof_date rows between 179 preceding and current row) as requests_last_180day,
    sum(requests) over (partition by agency_code order by asof_date rows between 364 preceding and current row) as requests_last_365day,

    -- Total Rolling Requests (previous period)
    sum(requests) over (partition by agency_code order by asof_date rows between 6 preceding and 3 preceding)   as requests_prev_3day,
    sum(requests) over (partition by agency_code order by asof_date rows between 14 preceding and 7 preceding)  as requests_prev_7day,
    sum(requests) over (partition by agency_code order by asof_date rows between 28 preceding and 14 preceding) as requests_prev_14day,
    sum(requests) over (partition by agency_code order by asof_date rows between 56 preceding and 28 preceding) as requests_prev_28day,

    sum(requests) over (partition by agency_code order by asof_date rows between 180 preceding and 90 preceding)  as requests_prev_90day,
    sum(requests) over (partition by agency_code order by asof_date rows between 360 preceding and 180 preceding) as requests_prev_180day,
    sum(requests) over (partition by agency_code order by asof_date rows between 730 preceding and 365 preceding) as requests_prev_365day,

    -- Average Rolling Requests
    avg(requests) over (partition by agency_code order by asof_date rows between 2 preceding and current row)  as avg_requests_last_3day,
    avg(requests) over (partition by agency_code order by asof_date rows between 6 preceding and current row)  as avg_requests_last_7day,
    avg(requests) over (partition by agency_code order by asof_date rows between 13 preceding and current row) as avg_requests_last_14day,
    avg(requests) over (partition by agency_code order by asof_date rows between 27 preceding and current row) as avg_requests_last_28day,

    avg(requests) over (partition by agency_code order by asof_date rows between 89 preceding and current row)  as avg_requests_last_90day,
    avg(requests) over (partition by agency_code order by asof_date rows between 179 preceding and current row) as avg_requests_last_180day,
    avg(requests) over (partition by agency_code order by asof_date rows between 364 preceding and current row) as avg_requests_last_365day,

    -- Std Dev Rolling Requests
    stddev(requests) over (partition by agency_code order by asof_date rows between 2 preceding and current row)  as stddev_requests_last_3day,
    stddev(requests) over (partition by agency_code order by asof_date rows between 6 preceding and current row)  as stddev_requests_last_7day,
    stddev(requests) over (partition by agency_code order by asof_date rows between 13 preceding and current row) as stddev_requests_last_14day,
    stddev(requests) over (partition by agency_code order by asof_date rows between 27 preceding and current row) as stddev_requests_last_28day,

    stddev(requests) over (partition by agency_code order by asof_date rows between 89 preceding and current row)  as stddev_requests_last_90day,
    stddev(requests) over (partition by agency_code order by asof_date rows between 179 preceding and current row) as stddev_requests_last_180day,
    stddev(requests) over (partition by agency_code order by asof_date rows between 364 preceding and current row) as stddev_requests_last_365day,

    -- Rolling Days with Requests
    sum(if(requests > 0, 1, 0)) over (partition by agency_code order by asof_date rows between 2 preceding and current row)  as request_days_last_3day,
    sum(if(requests > 0, 1, 0)) over (partition by agency_code order by asof_date rows between 6 preceding and current row)  as request_days_last_7day,
    sum(if(requests > 0, 1, 0)) over (partition by agency_code order by asof_date rows between 13 preceding and current row) as request_days_last_14day,
    sum(if(requests > 0, 1, 0)) over (partition by agency_code order by asof_date rows between 27 preceding and current row) as request_days_last_28day,

    sum(if(requests > 0, 1, 0)) over (partition by agency_code order by asof_date rows between 89 preceding and current row)  as request_days_last_90day,
    sum(if(requests > 0, 1, 0)) over (partition by agency_code order by asof_date rows between 179 preceding and current row) as request_days_last_180day,
    sum(if(requests > 0, 1, 0)) over (partition by agency_code order by asof_date rows between 364 preceding and current row) as request_days_last_365day,

  from service_requests_w_dates
),

service_requests_ratios as (
  select
    *,

    -- Coefficient of Variation (CV)
    safe_divide(stddev_requests_last_3day, avg_requests_last_3day)   as cv_requests_last_3day,
    safe_divide(stddev_requests_last_7day, avg_requests_last_7day)   as cv_requests_last_7day,
    safe_divide(stddev_requests_last_14day, avg_requests_last_14day) as cv_requests_last_14day,
    safe_divide(stddev_requests_last_28day, avg_requests_last_28day) as cv_requests_last_28day,

    safe_divide(stddev_requests_last_90day, avg_requests_last_90day)   as cv_requests_last_90day,
    safe_divide(stddev_requests_last_180day, avg_requests_last_180day) as cv_requests_last_180day,
    safe_divide(stddev_requests_last_365day, avg_requests_last_365day) as cv_requests_last_365day,

    -- Date Part Comparisons
    safe_divide(requests_last_3day, requests_prev_3day)   as requests_pop_3day,
    safe_divide(requests_last_7day, requests_prev_7day)   as requests_pop_7day,
    safe_divide(requests_last_14day, requests_prev_14day) as requests_pop_14day,
    safe_divide(requests_last_28day, requests_prev_28day) as requests_pop_28day,

    safe_divide(requests_last_90day, requests_prev_90day)  as requests_pop_90day,
    safe_divide(requests_last_180day, requests_prev_180day) as requests_pop_180day,
    safe_divide(requests_last_365day, requests_prev_365day) as requests_pop_365day,

  from service_requests_metrics
)

select 
    *,
    if(requests_next_1day is null, false, true) as has_requests_next_1day,
    if(requests_next_7day is null, false, true) as has_requests_next_7day,
from service_requests_ratios
order by agency_code, asof_date
