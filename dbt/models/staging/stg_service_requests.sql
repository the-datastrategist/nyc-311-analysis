{{ config(materialized='view') }}

with

base as (
    select *
    from {{ source('nyc_311', '311_service_requests') }}
),

base_w_agency_code as (
    select 
        case
            when agency like 'M%S OFFICE OF SPECIAL ENFORCEMENT' then 'OTHER'
            when agency in (
                '3-1-1',
                'DCAS',
                'ACS',
                'TAX',
                'DVS',
                'DCP',
                'DORIS',
                'FDNY',
                'TAT',
                'COIB',
                'CEO',
                'MOC',
                'OMB'
            ) then 'OTHER'
        else agency
        end as agency_code,
        *
    from base
),

base_w_complaint_type_normalized as (
    select 
        concat(
        lower(agency_code),'-',
        replace(
        regexp_replace(
            lower(complaint_type), 
            r'[^A-Za-z0-9 ]', ''), ' ', '-')) as complaint_type_normalized,
        *
    from base_w_agency_code
),

base_w_metrics as (
    select 
        *,
        date_diff(closed_date, created_date, hour) as hours_to_close
    from base_w_complaint_type_normalized
)

select * from base_w_metrics
