-- One row per customer (parent-rolled-up) per month-end at which the customer is paying, plus one churn row
-- (is_paying = false, is_churned = true) at the first month-end after a paying month-end where the customer is not paying.
-- is_opening_customer marks rows where the customer was paying at the previous month-end (the churn-rate denominator).
with months as (
    select
        month_end,
        lag(month_end) over (order by month_end) as prev_month_end,
        lead(month_end) over (order by month_end) as next_month_end
    from (select distinct month_end from {{ ref('sem_subscription_months') }})
),
paying as (
    select customer_id, month_end
    from {{ ref('sem_subscription_months') }}
    where is_paying
    group by all
),
flagged as (
    select
        p.customer_id,
        p.month_end,
        row_number() over (partition by p.customer_id order by p.month_end) = 1 as is_first_paying_month,
        prev.customer_id is not null as was_paying_prior_month_end
    from paying p
    join months m on m.month_end = p.month_end
    left join paying prev on prev.customer_id = p.customer_id and prev.month_end = m.prev_month_end
),
churn as (
    select p.customer_id, m.next_month_end as month_end
    from paying p
    join months m on m.month_end = p.month_end and m.next_month_end is not null
    left join paying nxt on nxt.customer_id = p.customer_id and nxt.month_end = m.next_month_end
    where nxt.customer_id is null
),
customer_rows as (
    select customer_id, month_end, true as is_paying, false as is_churned, is_first_paying_month as is_new_customer,
           was_paying_prior_month_end as is_opening_customer
    from flagged
    union all
    select customer_id, month_end, false, true, false, true
    from churn
),
customers as (
    select distinct customer_id, customer_segment, customer_region, customer_country, customer_billing_currency
    from {{ ref('sem_accounts') }}
)
select
    r.customer_id,
    r.month_end,
    r.is_paying,
    r.is_churned,
    r.is_new_customer,
    r.is_opening_customer,
    c.customer_segment,
    c.customer_region,
    c.customer_country,
    c.customer_billing_currency
from customer_rows r
join customers c on c.customer_id = r.customer_id
