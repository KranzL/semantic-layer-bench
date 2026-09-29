{{ config(materialized='table', schema='marts') }}

-- Credit notes (refunds) issued against paid invoices of external accounts.
-- Excludes internal accounts. USD at the credit-note issue-date FX rate.
select
    n.credit_note_id,
    n.invoice_id,
    n.account_id,
    coalesce(a.parent_account_id, a.account_id) as customer_id,
    n.issued_date,
    n.reason,
    n.currency,
    n.amount_minor / power(10, n.minor_unit_exponent) as amount_local,
    n.amount_minor / power(10, n.minor_unit_exponent) * n.usd_per_unit as amount_usd
from {{ ref('fct_credit_notes') }} n
join {{ ref('dim_accounts') }} a on a.account_id = n.account_id
where not a.is_internal
  and not a.is_deleted
