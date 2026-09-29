{{ config(materialized='table', schema='semantic') }}

-- Month-grain time spine carrying Relay's fiscal calendar (fiscal year starts 1 February;
-- FY2025 = Feb 2024 .. Jan 2025). Used by MetricFlow as custom granularities so metrics can
-- be grouped by fiscal_year and fiscal_quarter.
select
    calendar_month as date_month,
    'FY' || cast(fiscal_year as varchar) as fiscal_year,
    'FY' || cast(fiscal_year as varchar) || '-Q' || cast(fiscal_quarter as varchar) as fiscal_quarter,
    'FY' || cast(fiscal_year as varchar) || '-M' || lpad(cast(fiscal_month as varchar), 2, '0') as fiscal_month
from {{ ref('dim_date') }}
where date_day = calendar_month
