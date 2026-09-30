{{ config(materialized='table', schema='semantic') }}

-- Daily spine carrying Relay's fiscal calendar (FY starts 1 Feb; FY2025 = 2024-02-01..2025-01-31).
select
    cast(date_day as date) as date_day,
    'FY' || cast(fiscal_year as varchar) as fiscal_year,
    'FY' || cast(fiscal_year as varchar) || '-Q' || cast(fiscal_quarter as varchar) as fiscal_quarter
from {{ ref('dim_date') }}
