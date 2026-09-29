{{ config(materialized='table', schema='marts') }}

-- Credit notes issued against invoices of external, non-deleted accounts.
-- Every credit note in the data is against a paid invoice, so each one is money
-- returned to the customer (a refund). Amounts are converted from the credit
-- note currency's minor units to USD at the FX rate of the issue date.
select
    n.credit_note_id,
    n.invoice_id,
    n.account_id,
    a.customer_id,
    n.issued_date,
    n.reason as refund_reason,
    n.currency,
    n.amount_minor / power(10, n.minor_unit_exponent) * n.usd_per_unit as refund_usd
from {{ ref('fct_credit_notes') }} n
join {{ ref('sem_accounts') }} a on a.account_id = n.account_id
where a.is_reportable
