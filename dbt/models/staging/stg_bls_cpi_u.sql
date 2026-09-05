{{ config(materialized='view') }}

-- This is a staging model for the BLS CPI U dataset
select *
from {{ source('bls', 'cpi_u') }}
