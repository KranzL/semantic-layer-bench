{{ config(materialized='table', schema='marts') }}

-- Finalised customer invoices: status open, paid or uncollectible. Excludes
-- draft (never issued) and void (cancelled and re-issued as a new invoice, so
-- counting them would double count) invoices, and invoices of internal accounts.
-- Amounts are converted from minor units and to USD at the issue-date FX rate.
select
    i.invoice_id,
    i.account_id,
    coalesce(a.parent_account_id, a.account_id) as customer_id,
    i.subscription_id,
    i.invoice_type,
    i.status,
    i.issued_date,
    i.currency,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) as net_amount_local,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) * i.usd_per_unit as net_amount_usd,
    i.discount_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as discount_usd,
    i.tax_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as tax_usd,
    i.total_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as total_usd
from {{ ref('fct_invoices') }} i
join {{ ref('dim_accounts') }} a on a.account_id = i.account_id
where i.status in ('open', 'paid', 'uncollectible')
  and not a.is_internal
  and not a.is_deleted
