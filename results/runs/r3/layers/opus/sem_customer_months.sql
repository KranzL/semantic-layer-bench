-- Customer (logo) lifecycle by calendar month, built from the month-end MRR snapshot.
-- One row per customer per month in which the customer was paying at month end, or was
-- paying at the previous month end (so churn months are present).
with paying as (
    select customer_id, month_start, sum(mrr_usd) as mrr_usd
    from {{ ref('sem_subscription_mrr') }}
    group by all
),
months as (
    select distinct month_start from {{ ref('sem_subscription_mrr') }}
),
first_paid as (
    select customer_id, min(month_start) as first_paying_month
    from paying
    group by all
),
grid as (
    select
        f.customer_id,
        f.first_paying_month,
        m.month_start,
        p.mrr_usd,
        p.customer_id is not null as is_paying
    from first_paid f
    join months m on m.month_start >= f.first_paying_month
    left join paying p on p.customer_id = f.customer_id and p.month_start = m.month_start
),
with_prev as (
    select
        *,
        coalesce(lag(is_paying) over (partition by customer_id order by month_start), false) as was_paying_prior_month
    from grid
)
select
    w.customer_id || '-' || strftime(w.month_start, '%Y%m') as customer_month_id,
    w.customer_id,
    w.month_start,
    d.fiscal_year,
    'FY' || d.fiscal_year || ' Q' || d.fiscal_quarter as fiscal_quarter,
    coalesce(w.mrr_usd, 0) as mrr_usd,
    case when w.is_paying then 1 else 0 end as is_paying,
    case when w.was_paying_prior_month then 1 else 0 end as was_paying_prior_month,
    case when w.is_paying and w.month_start = w.first_paying_month then 1 else 0 end as is_new,
    case when w.is_paying and not w.was_paying_prior_month and w.month_start > w.first_paying_month then 1 else 0 end as is_reactivated,
    case when not w.is_paying and w.was_paying_prior_month then 1 else 0 end as is_churned
from with_prev w
join {{ ref('dim_date') }} d on d.date_day = w.month_start
where w.is_paying or w.was_paying_prior_month
