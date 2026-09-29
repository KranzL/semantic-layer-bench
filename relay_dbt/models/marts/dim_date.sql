select
    calendar_date as date_day,
    cast(date_trunc('month', calendar_date) as date) as calendar_month,
    cast(last_day(calendar_date) as date) as calendar_month_end,
    calendar_date = last_day(calendar_date) as is_month_end,
    extract(year from calendar_date) as calendar_year,
    fiscal_year,
    fiscal_quarter,
    fiscal_month
from {{ ref('stg_fiscal_calendar') }}
