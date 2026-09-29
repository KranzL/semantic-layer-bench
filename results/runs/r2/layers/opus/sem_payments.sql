{{ config(materialized='table', schema='marts') }}

-- Payment attempts against invoices of external, non-deleted accounts, both
-- succeeded and failed. Amounts are gross (include tax) and converted from the
-- payment currency's minor units to USD at the FX rate of the received date.
select
    p.payment_id,
    p.invoice_id,
    p.account_id,
    a.customer_id,
    i.invoice_type,
    p.received_date,
    p.status as payment_status,
    p.method as payment_method,
    p.currency,
    p.amount_minor / power(10, p.minor_unit_exponent) * p.usd_per_unit as amount_usd
from {{ ref('fct_payments') }} p
join {{ ref('fct_invoices') }} i on i.invoice_id = p.invoice_id
join {{ ref('sem_accounts') }} a on a.account_id = p.account_id
where a.is_reportable
