{{ config(materialized='view') }}

-- This is a staging model for the BLS CPI U dataset
select *
from `bigquery-public-data.google_analytics_sample.ga_sessions_*`
