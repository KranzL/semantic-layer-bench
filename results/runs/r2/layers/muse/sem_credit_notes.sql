select
    c.credit_note_id as row_key,
    c.issued_date,
    c.credit_note_id,
    c.invoice_id,
    c.reason as credit_reason,
    c.currency,
    c.account_id,
    a.account_name,
    a.segment,
    a.region,
    a.country,
    a.billing_currency,
    a.parent_account_id,
    c.amount_minor / power(10, c.minor_unit_exponent) * c.usd_per_unit as refund_usd
from {{ ref('fct_credit_notes') }} c
join {{ ref('dim_accounts') }} a on a.account_id = c.account_id
where not a.is_internal and not a.is_deleted
