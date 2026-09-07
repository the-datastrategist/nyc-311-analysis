{{ config(materialized='table') }}

with 

service_requests as (
  select distinct created_date
  from {{ ref('stg_service_requests') }}
),

calendar as (
  select asof_date
  from unnest(
    generate_date_array(
        (select date(min(created_date)) from service_requests),
        (select date(max(created_date)) from service_requests)
  )) as asof_date
),

holidays as (
  select
    region,
    holiday_name,
    primary_date,
    coalesce(preholiday_days, 0)  as preholiday_days,
    coalesce(postholiday_days, 0) as postholiday_days
  from {{ ref('stg_calendar') }}
  where region = 'US'
),

calendar_holidays as (
  select
    c.asof_date,
    h.region,
    coalesce(h.holiday_name, 'none') as holiday_name,
    h.primary_date,
    coalesce(h.preholiday_days, 0)   as preholiday_days,
    coalesce(h.postholiday_days, 0)  as postholiday_days,
    coalesce(c.asof_date = h.primary_date, false) as is_holiday,
    date_diff(c.asof_date, h.primary_date, day)   as days_since_holiday,
    extract(dayofweek from asof_date) as asof_dayofweek,
    extract(day from asof_date)       as asof_day,
    extract(month from asof_date)     as asof_month,
    extract(year from asof_date)      as asof_year
  from calendar c
  left join holidays h
    on c.asof_date between
      date_sub(h.primary_date, interval h.preholiday_days day)
      and date_add(h.primary_date, interval h.postholiday_days day)
),

calendar_numbers as (
  select
    * except(days_since_holiday),
    coalesce(days_since_holiday, 0)   as days_since_holiday,
    if(days_since_holiday is null, false, true) as has_days_since_holiday,
    asof_year * 12 + asof_month      as month_number,
    asof_year * 12 * 30 + asof_month * 30 + asof_day as day_number,
    sin(asof_year * 12 + asof_month) as sin_month_number,
    cos(asof_year * 12 + asof_month) as cos_month_number,
    sin(asof_year * 12 * 30 + asof_month * 30 + asof_day) as sin_day_number,
    cos(asof_year * 12 * 30 + asof_month * 30 + asof_day) as cos_day_number,
  from calendar_holidays
)

select *
from calendar_numbers
order by asof_date
