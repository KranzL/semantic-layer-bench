-- Cash received: succeeded payments from external accounts (failed payment attempts excluded).
-- Amount is the gross amount received (including tax), converted to USD at the receipt-date FX rate.
select
    p.payment_id,
    p.invoice_id,
    p.account_id,
    a.customer_id,
    p.method,
    p.currency,
    p.received_date,
    d.fiscal_year,
    'FY' || d.fiscal_year || ' Q' || d.fiscal_quarter as fiscal_quarter,
    p.amount_minor / power(10, p.minor_unit_exponent) * p.usd_per_unit as cash_collected_usd
from {{ ref('fct_payments') }} p
join {{ ref('sem_accounts') }} a on a.account_id = p.account_id
join {{ ref('dim_date') }} d on d.date_day = p.received_date
where p.status = 'succeeded'
