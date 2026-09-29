{{ config(materialized='table', schema='marts') }}

-- Daily time spine carrying Relay's fiscal calendar as MetricFlow custom
-- granularities. The fiscal year starts Feb 1 and is named for the calendar
-- year it ends in (FY2025 = 2024-02-01 to 2025-01-31). Each custom granularity
-- value is the first date of the fiscal period.
select
    cast(date_day as date) as date_day,
    cast(min(date_day) over (partition by fiscal_year, fiscal_quarter) as date) as fiscal_quarter,
    cast(min(date_day) over (partition by fiscal_year) as date) as fiscal_year
from {{ ref('dim_date') }}
