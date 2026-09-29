BUILDER = """You are the analytics engineer at Relay, a B2B SaaS company that sells seat-based subscriptions. The dbt project in ./relay_dbt models the billing and sales warehouse (DuckDB): raw source tables in schema raw, staging views in schema staging, and mart tables in schema marts.

Build the company's dbt semantic layer so that business users and AI assistants can answer finance and sales questions consistently from it. Write MetricFlow semantic models and metrics as YAML files in ./relay_dbt/models/semantic/. Cover the SaaS metrics the finance and sales teams ask about: MRR, ARR, paying customers, ARPA, new customers, logo churn and churn rate, billings, recognized revenue, cash collected, refunds, billable usage, bookings, new bookings and win rate, with the dimensions people slice them by (segment, region, currency, plan, sales team and so on). Give every semantic model, dimension, measure and metric a description that says exactly what it includes and excludes. Work out the business logic from the data.

Tools, run from this directory:
- ./query "SQL" runs read-only DuckDB SQL against the warehouse and prints CSV.
- ./dbt <args> runs dbt in the project, for example ./dbt parse. If a metric needs a helper model, add a SQL model in models/semantic/ and build it with ./dbt build --select path:models/semantic.
- ./mf <args> runs the MetricFlow CLI, for example ./mf validate-configs, ./mf list metrics, ./mf query --metrics <name> --group-by metric_time__month.

Only files in relay_dbt/models/semantic/ are kept; changes anywhere else are discarded. You are done when ./dbt parse and ./mf validate-configs both pass. Reply with a short summary of what you defined."""

QUERIER = """You are a data analyst at Relay, a B2B SaaS company. Answer the question below from the company's DuckDB warehouse.

Tools, run from this directory:
- ./query "SQL" runs read-only SQL and prints CSV. The analytics tables are in schema marts.
{layer}
Question: {question}

Give the final answer as one value: a number in plain digits with no units, currency symbols or thousands separators (money in USD, rates and shares as a fraction between 0 and 1), or a name if the question asks for one."""

LAYER = """- The analytics team maintains a semantic layer holding the company's official metric definitions. Its dbt MetricFlow YAML is in ./semantic_layer/. ./mf runs the MetricFlow CLI against it: ./mf list metrics, ./mf list dimensions --metrics <names>, ./mf query --metrics <names> --group-by <dimensions> [--where "<filter>"] [--start-time YYYY-MM-DD --end-time YYYY-MM-DD].
"""

ANSWER_SCHEMA = {
    "type": "object",
    "properties": {
        "answer": {"type": "string", "description": "The final answer as one value, no prose."},
        "method": {"type": "string", "description": "The final SQL or ./mf command that produced the answer."},
    },
    "required": ["answer", "method"],
    "additionalProperties": False,
}

BUILD_SCHEMA = {
    "type": "object",
    "properties": {"summary": {"type": "string"}},
    "required": ["summary"],
    "additionalProperties": False,
}


def querier(question, has_layer):
    return QUERIER.format(question=question, layer=LAYER if has_layer else "")
