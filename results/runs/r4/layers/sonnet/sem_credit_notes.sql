{{ config(materialized='table') }}
-- Credit notes on invoices of external accounts, in USD at the issue-date FX rate.
select
    n.credit_note_id,
    n.invoice_id,
    n.account_id,
    n.issued_date,
    n.reason,
    n.currency,
    n.amount_minor / power(10, n.minor_unit_exponent) * n.usd_per_unit as amount_usd
from {{ ref('fct_credit_notes') }} n
join {{ ref('sem_accounts') }} a on a.account_id = n.account_id
