{{ config(materialized='table', schema='marts') }}

-- Recognised revenue per invoice per calendar month. Subscription invoices are
-- recognised ratably per day over the service period; services invoices are
-- recognised in full on the issue date. Amounts are net of discounts and
-- exclude tax. Only finalised invoices (open, paid, uncollectible) of external
-- accounts; draft and void invoices are excluded. USD at the invoice
-- issue-date FX rate.
select
    r.invoice_id || '|' || cast(r.recognized_month as varchar) as revenue_row_id,
    r.invoice_id,
    r.account_id,
    coalesce(a.parent_account_id, a.account_id) as customer_id,
    r.invoice_type,
    r.status,
    r.recognized_month,
    r.currency,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent) as recognized_amount_local,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent) * r.usd_per_unit as recognized_amount_usd
from {{ ref('fct_revenue_recognition') }} r
join {{ ref('dim_accounts') }} a on a.account_id = r.account_id
where r.status in ('open', 'paid', 'uncollectible')
  and not a.is_internal
  and not a.is_deleted
