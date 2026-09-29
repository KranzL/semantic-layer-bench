{{ config(materialized='table', schema='semantic') }}

-- One row per credit note, excluding internal accounts, with amounts in major
-- currency units and in USD at the FX rate on the credit note issue date.
-- Every credit note in the warehouse is issued against an invoice that had
-- already been paid in full, after the payment date, so credit notes are cash
-- refunds returned to the customer. reason explains why: billing_error,
-- downgrade_adjustment, goodwill or service_credit.
with notes as (
    select * from {{ ref('fct_credit_notes') }}
),
inv as (
    select invoice_id, customer_id, invoice_type, plan_id, plan_family, billing_interval, issued_date, total_usd
    from {{ ref('sem_invoices') }}
)
select
    n.credit_note_id,
    n.invoice_id,
    n.account_id,
    i.customer_id,
    i.invoice_type,
    i.plan_id,
    i.plan_family,
    i.billing_interval,
    n.issued_at,
    n.issued_date,
    i.issued_date                                              as invoice_issued_date,
    datediff('day', i.issued_date, n.issued_date)              as days_after_invoice,
    n.reason,
    n.currency,
    n.minor_unit_exponent,
    n.usd_per_unit,
    n.amount_minor / power(10, n.minor_unit_exponent)                     as amount_local,
    n.amount_minor / power(10, n.minor_unit_exponent) * n.usd_per_unit    as amount_usd
from notes n
join inv i on i.invoice_id = n.invoice_id
