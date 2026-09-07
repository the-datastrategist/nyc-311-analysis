{{ config(materialized='view') }}

with

base as (
  select *
  from {{ source('calendar', 'holidays_and_events_for_forecasting') }}
  where region = 'US'
  qualify row_number() over (partition by primary_date order by preholiday_days desc) = 1
)

select * from base
