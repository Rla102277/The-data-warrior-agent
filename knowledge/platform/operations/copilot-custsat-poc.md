# CustSat Copilot POC (Foundation Development)

**Created:** 2026-08-19  
**Workspace:** Foundation Development only (`40502864-6ece-49b5-807f-6f7c11d1b3e1`)  
**Folder:** `analytics/operations`  
**Status:** Published POC. No schedule. Not promoted to Foundation.

Talk to customer-satisfaction data in the Fabric Data Agent Copilot pane.

## Artifact

| Field | Value |
|---|---|
| Name | `data_agent_operations_customer_survey` |
| ID | `b3061a00-caa4-4207-943f-2445b42612a1` |
| Source | `lake_house_analytics.operations.customer_survey_obt` (108,495 rows on 2026-08-19) |
| Grain | One row per question response (`response_id`) |
| Excluded columns | `buyer_name`, `buyer_email`, `buyer_phone` |
| Rebuild | `python3 automation/build_custsat_data_agent.py` |

Open in Fabric: [data_agent_operations_customer_survey](https://app.fabric.microsoft.com/groups/40502864-6ece-49b5-807f-6f7c11d1b3e1/dataagents/b3061a00-caa4-4207-943f-2445b42612a1)

MCP (after publish): `https://api.fabric.microsoft.com/v1/mcp/workspaces/40502864-6ece-49b5-807f-6f7c11d1b3e1/dataagents/b3061a00-caa4-4207-943f-2445b42612a1/agent`

## Tenant prereq

Confirmed 2026-08-19: **Users can use Copilot and other features powered by Azure OpenAI** (`EnableAOAI`) is **on**. Capacity is West US 3 (US). Shared F32 `gbpwus3fabric01`. Copilot uses CUs; demo outside Enterprise orch minutes `:06/:21/:36/:51`.

## How to chat

1. Open Foundation Development.
2. Open `analytics/operations` / `data_agent_operations_customer_survey`.
3. Use the Copilot pane. Ask CustSat questions only.

Count **surveys** as distinct `survey_response_id`. Scores use `rating_value` where `question_type_name = 'Rating'`. Survey buckets: Move-In, Mid-Year, Year-End, Closing.

## Smoke test (2026-08-19)

Checked against lakehouse SQL. Grain was correct (did not count `response_id` as surveys).

| Question | Agent | SQL check |
|---|---|---|
| Average Move-In rating by operating unit | Per-OU averages ~8.3 to 9.7 | Match (CB JENI 9.70, Southgate 9.67, Centre Living 8.29) |
| Year-End surveys completed this year | 0 | Match (`COUNT(DISTINCT survey_response_id)` = 0 for 2026) |
| Lowest average rating questions | Same top 5, 8.44 to 8.96 | Match |

## Out of scope

- Copilot Studio / Teams / Microsoft 365 Copilot
- Power BI report Copilot pane
- Foundation (prod twin) copy
- Other subjects (sales, lot events, finance)
- Recurring schedules or hydration

## Rebuild notes

Do not bind the whole lakehouse. Do not add `*_active` twins. Lakehouse name is `lake_house_analytics` (D15).
