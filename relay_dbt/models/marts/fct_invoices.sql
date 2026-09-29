select
    i.invoice_id,
    i.invoice_number,
    i.account_id,
    i.subscription_id,
    i.invoice_type,
    i.status,
    i.issued_at,
    cast(i.issued_at as date) as issued_date,
    i.due_at,
    i.period_start,
    i.period_end,
    i.currency,
    c.minor_unit_exponent,
    i.subtotal_minor,
    i.discount_minor,
    i.tax_minor,
    i.total_minor,
    fx.usd_per_unit
from {{ ref('stg_invoices') }} i
join {{ ref('stg_currencies') }} c on c.currency = i.currency
join {{ ref('stg_fx_rates') }} fx on fx.currency = i.currency and fx.rate_date = cast(i.issued_at as date)
