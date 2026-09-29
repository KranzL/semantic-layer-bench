-- Recognized revenue by invoice and calendar month. Subscription invoices are recognized
-- ratably per day over their service period; services invoices on the issue date.
-- Only issued invoices (open, paid, uncollectible) of external accounts; excludes void and
-- draft invoices, tax, and credit notes. Converted to USD at the invoice issue-date FX rate.
-- Deferred revenue for months after the latest invoice month in the warehouse is excluded.
select
    r.invoice_id || '-' || strftime(r.recognized_month, '%Y%m') as revenue_line_id,
    r.invoice_id,
    r.account_id,
    a.customer_id,
    i.plan_id,
    r.invoice_type,
    r.currency,
    r.recognized_month,
    d.fiscal_year,
    'FY' || d.fiscal_year || ' Q' || d.fiscal_quarter as fiscal_quarter,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent) * r.usd_per_unit as recognized_revenue_usd
from {{ ref('fct_revenue_recognition') }} r
join {{ ref('sem_accounts') }} a on a.account_id = r.account_id
join {{ ref('sem_invoices') }} i on i.invoice_id = r.invoice_id
join {{ ref('dim_date') }} d on d.date_day = r.recognized_month
where r.status in ('open', 'paid', 'uncollectible')
  -- only months up to the data as-of month; later months are deferred (not yet earned) revenue
  and r.recognized_month <= (select date_trunc('month', max(issued_date)) from {{ ref('fct_invoices') }})
