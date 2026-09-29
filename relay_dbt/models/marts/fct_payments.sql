select
    p.payment_id,
    p.invoice_id,
    i.account_id,
    p.received_at,
    cast(p.received_at as date) as received_date,
    p.status,
    p.method,
    p.currency,
    c.minor_unit_exponent,
    p.amount_minor,
    fx.usd_per_unit
from {{ ref('stg_payments') }} p
join {{ ref('stg_invoices') }} i on i.invoice_id = p.invoice_id
join {{ ref('stg_currencies') }} c on c.currency = p.currency
join {{ ref('stg_fx_rates') }} fx on fx.currency = p.currency and fx.rate_date = cast(p.received_at as date)
