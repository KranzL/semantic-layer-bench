-- One row per invoice per recognition month. Subscription invoices are recognized ratably by day over the
-- service period [period_start, period_end); services invoices are recognized in full on the issue date.
-- Amounts are net of discounts and exclude tax. Draft and void invoices and internal accounts are excluded.
select
    r.invoice_id || '|' || cast(r.recognized_month as varchar) as revenue_line_id,
    r.invoice_id,
    r.account_id,
    a.customer_id,
    r.invoice_type,
    r.status as invoice_status,
    r.recognized_month,
    d.fiscal_year,
    d.fiscal_quarter,
    r.currency,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent) as recognized_amount_local,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent) * r.usd_per_unit as recognized_amount_usd
from {{ ref('fct_revenue_recognition') }} r
join {{ ref('sem_accounts') }} a on a.account_id = r.account_id
join {{ ref('sem_fiscal_time_spine') }} d on d.date_day = r.recognized_month
where r.status in ('open', 'paid', 'uncollectible')
