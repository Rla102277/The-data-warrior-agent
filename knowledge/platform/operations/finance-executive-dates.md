# Finance executive dashboard dates and unit metrics

FD only. Finance production was not changed. Backlog dollars were left as-is.

## Intent

Card metrics should count the same event types as Weekly Unit, inside
MTD / QTD / YTD through an as-of date in Central time. A year slicer
and UTC `TODAY()` were the two date bugs. Unfiltered `Event Value`
was counting tasks and other non-unit events.

## Measure contract

All period cards use `calendar[full_date]` with `ALL(calendar)` so the
as-of slicer does not collapse the window to a single day.

| Measure | Rule |
|---|---|
| As Of Date | Max selected `calendar[full_date]` if the date slicer is filtered, else Central today (UTC-5 Mar 8 to Oct 31, UTC-6 otherwise) |
| Period Start Date | MTD month start, QTD quarter start, YTD Jan 1, from PeriodTable (default MTD) |
| Gross Sales / Sales | `event_type = Sale` |
| Cancels | `event_type = Cancel` |
| Net Sales | Gross minus Cancels |
| Closings | `event_type = Close` |
| Starts | `event_type = 1-Job Started` only (not Event Category Starts) |
| Closing Revenue | `net_revenue` on Close events in the window |
| Pending Sales / Projected Closings | Pending Sale / Pending Close, not period-sliced |
| Specs Under Construction | `lot` rows with `is_spec=1`, `is_started=1`, `is_completed=0` |

## Local artifacts

- `automation/deploy_finance_executive_metrics.py`
- `fabric/build/finance_executive/semantic_model_finance_executive_dashboard.SemanticModel`
- `automation/rebuild_sales_closings_dashboard.py` (Period + As of date slicers)
- `fabric/build/sales_closings/report_finance_executive_dashboard.Report`

## Live deploy 2026-09-19

Confirmed: items exist in Foundation Development
(`semantic_model_finance_executive_dashboard`
`4bf91a7c-…`, `report_finance_executive_dashboard` `e2b937b7-…`).

Failed: `getDefinition` / `updateDefinition` 404 EntityNotFound;
create same name 403 InsufficientPrivileges; Power BI
`executeQueries` 404 (no Build); dataset tables/datasources 403
(no write). The signed-in Fabric identity can list the items but
cannot replace the model or query it.

Redeploy when the operator has Contributor (or dataset Write/Build)
on Foundation Development:

`py -3.12 automation/deploy_finance_executive_metrics.py`

Do not enable a refresh schedule unless asked.
