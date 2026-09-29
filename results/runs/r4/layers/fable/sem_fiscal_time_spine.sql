{{ config(materialized='table', schema='semantic') }}

-- Daily spine carrying Relay's fiscal calendar. The fiscal year starts on
-- 1 February and is named for the calendar year in which it ends (FY2026 = Feb 2025 - Jan 2026).
select
    cast(date_day as date) as date_day,
    min(cast(date_day as date)) over (partition by fiscal_year) as fiscal_year,
    min(cast(date_day as date)) over (partition by fiscal_year, fiscal_quarter) as fiscal_quarter
from {{ ref('dim_date') }}
