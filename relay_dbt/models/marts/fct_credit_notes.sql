select
    n.credit_note_id,
    n.invoice_id,
    i.account_id,
    n.issued_at,
    cast(n.issued_at as date) as issued_date,
    n.reason,
    n.currency,
    c.minor_unit_exponent,
    n.amount_minor,
    fx.usd_per_unit
from {{ ref('stg_credit_notes') }} n
join {{ ref('stg_invoices') }} i on i.invoice_id = n.invoice_id
join {{ ref('stg_currencies') }} c on c.currency = n.currency
join {{ ref('stg_fx_rates') }} fx on fx.currency = n.currency and fx.rate_date = cast(n.issued_at as date)
