-- Successful payments from external accounts. Failed payments are excluded.
-- cash_usd is the amount received (including any tax on the invoice) converted at the FX rate on the received date.
select
    p.payment_id,
    p.invoice_id,
    p.account_id,
    a.customer_id,
    p.received_date,
    p.method,
    p.currency,
    p.amount_minor / pow(10, p.minor_unit_exponent) * p.usd_per_unit as cash_usd
from {{ ref('fct_payments') }} p
join {{ ref('sem_accounts') }} a on a.account_id = p.account_id
where p.status = 'succeeded'
