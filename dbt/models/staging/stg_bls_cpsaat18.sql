{{ config(materialized='view') }}

select *
from {{ source('bls', 'cpsaat18') }}
