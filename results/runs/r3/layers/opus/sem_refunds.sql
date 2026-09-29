-- Refunds: credit notes issued against paid invoices of external accounts.
-- Converted to USD at the credit-note issue-date FX rate.
select
    n.credit_note_id,
    n.invoice_id,
    n.account_id,
    a.customer_id,
    n.reason,
    n.currency,
    n.issued_date,
    d.fiscal_year,
    'FY' || d.fiscal_year || ' Q' || d.fiscal_quarter as fiscal_quarter,
    n.amount_minor / power(10, n.minor_unit_exponent) * n.usd_per_unit as refund_usd
from {{ ref('fct_credit_notes') }} n
join {{ ref('sem_accounts') }} a on a.account_id = n.account_id
join {{ ref('dim_date') }} d on d.date_day = n.issued_date
