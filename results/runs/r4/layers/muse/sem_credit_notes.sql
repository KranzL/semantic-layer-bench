{{ config(materialized='table', schema='marts') }}

select
    n.credit_note_id,
    n.invoice_id,
    n.account_id,
    n.issued_at,
    n.issued_date,
    n.reason,
    n.currency,
    n.amount_minor / power(10, n.minor_unit_exponent) * n.usd_per_unit as refunds_usd
from {{ ref('fct_credit_notes') }} n
join {{ ref('dim_accounts') }} a on a.account_id = n.account_id
where not a.is_internal and not a.is_deleted
