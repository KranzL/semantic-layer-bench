{{ config(materialized='table', schema='semantic') }}

-- Daily time spine carrying Relay's fiscal calendar. The fiscal year starts on
-- 1 February and is named for the calendar year in which it ends (FY2025 is
-- 2024-02-01 to 2025-01-31). Fiscal periods are labelled by their first day.
select
    cast(date_day as date) as date_day,
    min(cast(date_day as date)) over (partition by fiscal_year) as fiscal_year_start,
    min(cast(date_day as date)) over (partition by fiscal_year, fiscal_quarter) as fiscal_quarter_start
from {{ ref('dim_date') }}
