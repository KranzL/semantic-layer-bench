{{ config(materialized='table', schema='marts') }}

-- Finalized invoices (status open, paid or uncollectible) issued to external,
-- non-deleted accounts. Draft and void invoices are excluded because they were
-- never (or are no longer) a valid bill. Amounts are converted from the invoice
-- currency's minor units to USD at the FX rate of the issue date.
-- plan_id is the plan of the subscription version in effect at period start
-- (null for one-off services invoices).
select
    i.invoice_id,
    i.invoice_number,
    i.account_id,
    a.customer_id,
    i.subscription_id,
    v.plan_id,
    i.invoice_type,
    i.status as invoice_status,
    i.issued_date,
    i.currency,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) * i.usd_per_unit as billings_usd,
    i.subtotal_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as gross_billings_usd,
    i.discount_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as discount_usd,
    i.tax_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as tax_usd,
    i.total_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as total_invoiced_usd
from {{ ref('fct_invoices') }} i
join {{ ref('sem_accounts') }} a on a.account_id = i.account_id
left join {{ ref('stg_subscription_versions') }} v
    on v.subscription_id = i.subscription_id
    and i.period_start >= v.valid_from
    and (v.valid_to is null or i.period_start < v.valid_to)
where a.is_reportable
  and i.status in ('open', 'paid', 'uncollectible')
