-- One row per payment attempt for external (non-internal) accounts, succeeded and failed.
-- Amounts converted to USD at the FX rate of the received date.
select
    p.payment_id,
    p.invoice_id,
    p.account_id,
    a.customer_id,
    i.invoice_type,
    p.received_date,
    f.fiscal_year,
    f.fiscal_quarter,
    p.status,
    p.method,
    p.currency,
    p.amount_minor / power(10, p.minor_unit_exponent) as amount_local,
    p.amount_minor / power(10, p.minor_unit_exponent) * p.usd_per_unit as amount_usd
from {{ ref('fct_payments') }} p
join {{ ref('sem_accounts') }} a on a.account_id = p.account_id
join {{ ref('stg_invoices') }} i on i.invoice_id = p.invoice_id
join {{ ref('sem_fiscal_time_spine') }} f on f.date_day = p.received_date
