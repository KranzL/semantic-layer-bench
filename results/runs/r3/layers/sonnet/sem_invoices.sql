-- Issued invoices of external accounts (status open, paid, uncollectible). Draft and void invoices are excluded.
-- billed_usd is net of discount and excludes tax, converted at the FX rate on the issue date.
select
    i.invoice_id,
    i.account_id,
    a.customer_id,
    i.invoice_type,
    i.status,
    i.issued_date,
    i.currency,
    (i.subtotal_minor - i.discount_minor) / pow(10, i.minor_unit_exponent) * i.usd_per_unit as billed_usd
from {{ ref('fct_invoices') }} i
join {{ ref('sem_accounts') }} a on a.account_id = i.account_id
where i.status in ('open', 'paid', 'uncollectible')
