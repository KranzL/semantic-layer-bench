select rep_id, rep_name, team as sales_team, region as rep_region from {{ ref('dim_sales_reps') }}
