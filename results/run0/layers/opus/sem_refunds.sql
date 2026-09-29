-- One row per credit note for external (non-internal) accounts. Every credit note is issued against an invoice
-- that has already been paid, so credit notes are Relay's refunds of collected cash.
-- Amounts converted to USD at the FX rate of the credit note issue date.
select
    n.credit_note_id,
    n.invoice_id,
    n.account_id,
    a.customer_id,
    i.invoice_type,
    n.issued_date,
    f.fiscal_year,
    f.fiscal_quarter,
    n.reason,
    n.currency,
    n.amount_minor / power(10, n.minor_unit_exponent) as amount_local,
    n.amount_minor / power(10, n.minor_unit_exponent) * n.usd_per_unit as amount_usd
from {{ ref('fct_credit_notes') }} n
join {{ ref('sem_accounts') }} a on a.account_id = n.account_id
join {{ ref('stg_invoices') }} i on i.invoice_id = n.invoice_id
join {{ ref('sem_fiscal_time_spine') }} f on f.date_day = n.issued_date
