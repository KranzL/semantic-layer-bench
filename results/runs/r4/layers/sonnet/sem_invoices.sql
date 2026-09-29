{{ config(materialized='table') }}
-- Invoices of external accounts with amounts converted to USD at the issue-date FX rate.
select
    i.invoice_id,
    i.account_id,
    i.invoice_type,
    i.status,
    i.issued_date,
    i.currency,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) * i.usd_per_unit as net_usd
from {{ ref('fct_invoices') }} i
join {{ ref('sem_accounts') }} a on a.account_id = i.account_id
