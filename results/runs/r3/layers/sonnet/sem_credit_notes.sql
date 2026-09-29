-- Credit notes issued to external accounts; the warehouse has no negative payments, so credit notes are the refunds/credits.
-- refund_usd is the credit note amount as recorded, converted at the FX rate on the issue date.
select
    n.credit_note_id,
    n.invoice_id,
    n.account_id,
    a.customer_id,
    n.issued_date,
    n.reason,
    n.currency,
    n.amount_minor / pow(10, n.minor_unit_exponent) * n.usd_per_unit as refund_usd
from {{ ref('fct_credit_notes') }} n
join {{ ref('sem_accounts') }} a on a.account_id = n.account_id
