{{ config(materialized='table', schema='semantic') }}

-- One row per credit note, for reportable accounts only (internal and soft-deleted
-- accounts excluded). In this warehouse every credit note is issued against an invoice
-- that was already paid, after the payment, and never exceeds the invoice total, so a
-- credit note is money returned to the customer: a refund. Reasons: billing_error,
-- downgrade_adjustment, goodwill, service_credit. Amounts are converted to USD at the
-- FX rate on the day the credit note was issued.
with cn as (
    select * from {{ ref('fct_credit_notes') }}
),
inv as (
    select invoice_id, invoice_type from {{ ref('fct_invoices') }}
),
accounts as (
    select * from {{ ref('sl_accounts') }} where is_reportable
)
select
    n.credit_note_id,
    n.invoice_id,
    i.invoice_type,
    n.account_id,
    a.customer_id,
    n.issued_date,
    cast(date_trunc('month', n.issued_date) as date) as issued_month,
    n.reason,
    n.currency,
    n.minor_unit_exponent,
    n.usd_per_unit,
    n.amount_minor / power(10, n.minor_unit_exponent) as amount_local,
    n.amount_minor / power(10, n.minor_unit_exponent) * n.usd_per_unit as amount_usd
from cn n
join accounts a on a.account_id = n.account_id
join inv i on i.invoice_id = n.invoice_id
