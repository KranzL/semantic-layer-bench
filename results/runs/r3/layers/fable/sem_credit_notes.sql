{{ config(materialized='table', schema='semantic') }}

-- One row per credit note issued against an invoice of a non-internal account.
-- In this warehouse credit notes are the only mechanism that returns or credits
-- money to a customer (payments are never negative), so they are the basis of
-- the refunds metric. Amounts are converted to major units and to USD at the
-- FX rate on the credit note issue date.
with credit_notes as (
    select * from {{ ref('fct_credit_notes') }}
),
invoices as (
    select invoice_id, invoice_type, status as invoice_status from {{ ref('fct_invoices') }}
),
accounts as (
    select account_id, is_internal from {{ ref('dim_accounts') }}
)
select
    n.credit_note_id,
    n.invoice_id,
    n.account_id,
    i.invoice_type,
    i.invoice_status,
    n.issued_date,
    n.reason as credit_reason,
    n.currency,
    n.minor_unit_exponent,
    n.usd_per_unit,
    n.amount_minor / power(10, n.minor_unit_exponent) as amount_local,
    n.amount_minor / power(10, n.minor_unit_exponent) * n.usd_per_unit as amount_usd
from credit_notes n
join invoices i on i.invoice_id = n.invoice_id
join accounts a on a.account_id = n.account_id
where not a.is_internal
