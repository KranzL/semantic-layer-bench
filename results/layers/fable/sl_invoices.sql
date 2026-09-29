{{ config(materialized='table', schema='semantic') }}

-- One row per invoice, all invoice types and statuses, for reportable accounts only
-- (internal and soft-deleted accounts excluded). Amounts are converted from minor units
-- to major units and to USD at the FX rate on the invoice issue date.
-- Statuses: draft (not yet issued), open (issued, unpaid, not overdue-written-off),
-- paid, uncollectible (issued, written off), void (cancelled; never counts).
-- is_issued = status in (open, paid, uncollectible): the invoices that count as billings.
with inv as (
    select * from {{ ref('fct_invoices') }}
),
accounts as (
    select * from {{ ref('sl_accounts') }} where is_reportable
)
select
    i.invoice_id,
    i.invoice_number,
    i.account_id,
    a.customer_id,
    i.subscription_id,
    i.invoice_type,
    i.status,
    i.status in ('open', 'paid', 'uncollectible') as is_issued,
    i.status = 'paid' as is_paid,
    i.issued_date,
    cast(date_trunc('month', i.issued_date) as date) as issued_month,
    i.due_at as due_date,
    i.period_start,
    i.period_end,
    i.currency,
    i.minor_unit_exponent,
    i.usd_per_unit,
    i.subtotal_minor / power(10, i.minor_unit_exponent) as subtotal_local,
    i.discount_minor / power(10, i.minor_unit_exponent) as discount_local,
    i.tax_minor / power(10, i.minor_unit_exponent) as tax_local,
    i.total_minor / power(10, i.minor_unit_exponent) as total_local,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) as net_local,
    i.subtotal_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as subtotal_usd,
    i.discount_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as discount_usd,
    i.tax_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as tax_usd,
    i.total_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as total_usd,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) * i.usd_per_unit as net_usd
from inv i
join accounts a on a.account_id = i.account_id
