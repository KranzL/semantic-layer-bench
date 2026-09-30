{{ config(materialized='table', schema='semantic') }}

-- One row per payment attempt on an invoice of a real account (internal and
-- soft-deleted accounts removed). Failed attempts are kept and flagged;
-- only succeeded payments are cash. Amounts are converted to USD at the FX
-- rate of the date the payment was received.
select
    p.payment_id,
    p.invoice_id,
    p.account_id,
    a.customer_id,
    p.received_date,
    p.status as payment_status,
    p.status = 'succeeded' as is_succeeded,
    p.method as payment_method,
    p.currency,
    p.amount_minor / power(10, p.minor_unit_exponent) * p.usd_per_unit as amount_usd
from {{ ref('fct_payments') }} p
join {{ ref('sem_accounts') }} a on a.account_id = p.account_id
