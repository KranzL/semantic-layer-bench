{{ config(materialized='table', schema='semantic') }}

-- One row per credit note (refund) issued against an invoice of a real
-- account (internal and soft-deleted accounts removed). Amounts are
-- converted to USD at the FX rate of the credit note issue date.
select
    n.credit_note_id,
    n.invoice_id,
    n.account_id,
    a.customer_id,
    n.issued_date,
    n.reason as refund_reason,
    n.currency,
    n.amount_minor / power(10, n.minor_unit_exponent) * n.usd_per_unit as amount_usd
from {{ ref('fct_credit_notes') }} n
join {{ ref('sem_accounts') }} a on a.account_id = n.account_id
