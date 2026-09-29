{{ config(materialized='table', schema='semantic') }}

-- Invoices of reportable accounts with amounts converted to USD at the issue-date FX rate.
-- is_billed marks finalised invoices (open, paid, uncollectible); draft and void are not billed.
select
    i.invoice_id,
    i.invoice_number,
    i.account_id,
    a.customer_id,
    i.subscription_id,
    v.plan_id,
    i.invoice_type,
    i.status,
    i.status in ('open', 'paid', 'uncollectible') as is_billed,
    i.issued_date,
    i.due_at as due_date,
    i.currency,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) * i.usd_per_unit as net_amount_usd,
    i.subtotal_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as subtotal_usd,
    i.discount_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as discount_usd,
    i.tax_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as tax_usd,
    i.total_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as total_usd
from {{ ref('fct_invoices') }} i
join {{ ref('sem_accounts') }} a on a.account_id = i.account_id
left join {{ ref('stg_subscription_versions') }} v
    on v.subscription_id = i.subscription_id
    and v.valid_from <= i.issued_date
    and (v.valid_to is null or i.issued_date < v.valid_to)
