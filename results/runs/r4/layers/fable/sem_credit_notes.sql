{{ config(materialized='table', schema='semantic') }}

-- Credit notes (refunds) of reportable accounts with amounts converted to USD at the
-- credit note's issue-date FX rate.
select
    n.credit_note_id,
    n.invoice_id,
    n.account_id,
    a.customer_id,
    i.plan_id,
    i.invoice_type,
    n.issued_date,
    n.reason,
    n.currency,
    n.amount_minor / power(10, n.minor_unit_exponent) * n.usd_per_unit as amount_usd
from {{ ref('fct_credit_notes') }} n
join {{ ref('sem_accounts') }} a on a.account_id = n.account_id
left join {{ ref('sem_invoices') }} i on i.invoice_id = n.invoice_id
