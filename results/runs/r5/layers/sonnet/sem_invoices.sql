{{ config(materialized='table', schema='marts') }}

-- Issued invoices (open, paid, uncollectible) for external customers. Drafts and voids are excluded.
-- Amounts are net of discount and exclude tax, converted to USD at the issue-date rate.
select
    i.invoice_id,
    i.account_id,
    i.issued_date,
    i.invoice_type,
    i.status,
    i.currency,
    a.segment,
    a.region,
    a.country,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) * i.usd_per_unit as billed_usd
from {{ ref('fct_invoices') }} i
join {{ ref('dim_accounts') }} a on a.account_id = i.account_id
where i.status in ('open', 'paid', 'uncollectible')
  and not a.is_internal
