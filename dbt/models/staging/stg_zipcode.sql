{{ config(materialized='view') }}

-- This is a staging model for the Census Bureau ZIP code dataset
select *
from {{ source('census_bureau', 'zip_codes_2018_5yr') }}
