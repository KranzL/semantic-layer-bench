with inv as (
    select * from {{ ref('fct_invoices') }}
),
subscription_days as (
    select
        inv.invoice_id,
        cast(d.date_day as date) as recognized_date,
        (inv.subtotal_minor - inv.discount_minor) * 1.0 / datediff('day', inv.period_start, inv.period_end) as amount_minor
    from inv
    join {{ ref('dim_date') }} d on d.date_day >= inv.period_start and d.date_day < inv.period_end
    where inv.invoice_type = 'subscription'
),
services as (
    select invoice_id, issued_date as recognized_date, (subtotal_minor - discount_minor) * 1.0 as amount_minor
    from inv
    where invoice_type = 'services'
),
all_days as (
    select * from subscription_days
    union all
    select * from services
)
select
    inv.invoice_id,
    inv.account_id,
    inv.invoice_type,
    inv.status,
    cast(date_trunc('month', a.recognized_date) as date) as recognized_month,
    inv.currency,
    inv.minor_unit_exponent,
    inv.usd_per_unit,
    sum(a.amount_minor) as recognized_amount_minor
from all_days a
join inv on inv.invoice_id = a.invoice_id
group by all
