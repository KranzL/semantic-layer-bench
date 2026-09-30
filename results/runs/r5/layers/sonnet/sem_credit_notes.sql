{{ config(materialized='table', schema='marts') }}

-- Credit notes issued to external customers, in USD at the issue-date rate. Amounts are tax-inclusive as issued.
select
    n.credit_note_id,
    n.invoice_id,
    n.account_id,
    n.issued_date,
    n.reason,
    n.currency,
    a.segment,
    a.region,
    a.country,
    n.amount_minor / power(10, n.minor_unit_exponent) * n.usd_per_unit as refunded_usd
from {{ ref('fct_credit_notes') }} n
join {{ ref('dim_accounts') }} a on a.account_id = n.account_id
where not a.is_internal
