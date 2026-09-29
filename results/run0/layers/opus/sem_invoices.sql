-- One row per invoice for external (non-internal) accounts, all statuses. Amounts converted to major units and
-- to USD at the FX rate of the issue date. Billings metrics filter to finalized invoices (open, paid, uncollectible).
select
    i.invoice_id,
    i.invoice_number,
    i.account_id,
    a.customer_id,
    i.subscription_id,
    i.invoice_type,
    i.status,
    i.status in ('open', 'paid', 'uncollectible') as is_billed,
    i.issued_date,
    f.fiscal_year,
    f.fiscal_quarter,
    cast(i.due_at as date) as due_date,
    i.period_start,
    i.period_end,
    i.currency,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) as net_amount_local,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) * i.usd_per_unit as net_amount_usd,
    i.discount_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as discount_amount_usd,
    i.tax_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as tax_amount_usd,
    i.total_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as total_amount_usd
from {{ ref('fct_invoices') }} i
join {{ ref('sem_accounts') }} a on a.account_id = i.account_id
join {{ ref('sem_fiscal_time_spine') }} f on f.date_day = i.issued_date
