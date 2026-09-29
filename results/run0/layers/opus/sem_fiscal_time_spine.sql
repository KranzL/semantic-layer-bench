-- Daily lookup of Relay's fiscal calendar (fiscal year starts 1 February; FY2025 = Feb 2024 – Jan 2025).
-- Joined onto the semantic fact models to expose fiscal_year / fiscal_quarter dimensions.
select
    cast(date_day as date) as date_day,
    fiscal_year,
    'FY' || fiscal_year || '-Q' || fiscal_quarter as fiscal_quarter
from {{ ref('dim_date') }}
