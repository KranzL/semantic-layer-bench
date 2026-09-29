-- Recognized revenue per issued invoice per calendar month for external accounts.
-- Subscription invoices are spread daily over their service period; services invoices are recognized on the issue date.
-- Draft and void invoices are excluded. Amounts are net of discount, exclude tax, converted at the invoice-date FX rate.
select
    r.invoice_id,
    r.account_id,
    a.customer_id,
    r.invoice_type,
    r.status,
    r.recognized_month,
    r.currency,
    r.recognized_amount_minor / pow(10, r.minor_unit_exponent) * r.usd_per_unit as recognized_usd
from {{ ref('fct_revenue_recognition') }} r
join {{ ref('sem_accounts') }} a on a.account_id = r.account_id
where r.status in ('open', 'paid', 'uncollectible')
