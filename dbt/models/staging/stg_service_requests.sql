{{ config(materialized='view') }}

select *
from {{ source('nyc_311', '311_service_requests') }}
