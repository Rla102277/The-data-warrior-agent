# Finance Executive Unit Dashboard date copy

Finance workspace only. Original `Executive Unit Dashboard` report and model
were not updated. Foundation Development was not touched.

## Copy

- Report: `Executive Unit Dashboard Date Copy`
  `https://app.fabric.microsoft.com/groups/9b62026a-4675-4ddb-a0ad-2177f597f114/reports/b37f0495-0423-45a1-b663-374b5ee8abd5`
- Model: `3d49d0ff-70bc-4293-919f-89acb229fd9b`
- Source report `b94d1b37-…` / source model `dd873611-…` unchanged

Copy changes that did deploy: calendar relationship uses date-only `Date`
instead of `Event Date` datetime. Unit measures (Gross Sales, Cancels,
Net Sales, Closings, Starts, Closing Revenue) default to Central MTD through
as-of. The Starts KPI on the copy uses the `Starts` measure
(`Event Type` = `1-Job Started`), not unfiltered `OutputEventValue`.

Date controls on the copy match Weekly Unit:
Time Period dropdown is WTD / MTD / YTD / Totals. Date is a
`Select Max Date` picker (On or before), not a date list and not a
Between range. Default with nothing selected is Central today and MTD.

Sales / Closings / Starts KPIs use `Net Sales`, `Closings`, and `Starts`
(period window), not unfiltered `OutputEventValue`.

## Validated unit counts (Central as-of 2026-09-20)

Queried read-only on the original Finance model with `Event Type` plus
`DATESBETWEEN` on `vw_dim_date[full_date]`. Matches the earlier Executive
Dashboard benchmark.

| Metric | MTD | QTD | YTD |
|---|---:|---:|---:|
| Gross Sale | 211 | 871 | 3174 |
| Cancel | 14 |  | 248 |
| Net (Gross minus Cancel) | 197 |  | 2926 |
| Close | 142 |  | 2755 |
| 1-Job Started | 203 |  | 2979 |
| Event Category Starts |  |  | 2981 |
| Close Net_Revenue | $66,357,478 |  | $1,539,939,851 |
| Sale Net_Revenue | $101,672,432 |  |  |

Unfiltered `OutputEventValue` = 281,499 (tasks dominate).
`OutputEventValue` MTD with no Event Type filter = 2,206.

## Accuracy gaps on the live original layout

1. Date slicer is Relative "This Month" (UTC today). That is the month-end
   GMT miss. Copy intended Between + Central as-of.
2. Sales KPI filters Sale + Cancel and uses `OutputEventValue`, so it is
   net (197 MTD), not gross. Weekly Unit gross is 211.
3. Starts KPI includes Revert to Dirt, which `OutputEventValue` negates.
   YTD 1-Job Started is 2979; category Starts is 2981.
4. Cancels card uses `Event Value` (positive 14). Lot Transfer (1 MTD) and
   Model Change are Cancel category but not Event Type Cancel, so they are
   excluded from cancel units and not negated in net sales.
5. One MTD row has blank Event Type (1 unit, $659,150). Not in Sale.
6. Closing $ and Sale $ both come from `Net_Revenue` on `vw_rep_lot_events`
   (ERP latest est), not SGM. Close MTD $66.4M vs Sale MTD $101.7M is
   expected if those are different events, not a dual of the same lots.
7. Pending Sale / Pending Close cards should stay snapshot, not MTD.
8. Unfiltered or task-inclusive visuals will never match Weekly Unit.

## Copy Starts (fixed 2026-09-21)

The copy Starts KPI was off because it summed `OutputEventValue` (every event
type, including tasks). All-time that is about 281k; MTD unfiltered is about
2,206. True job starts are `Event Type` = `1-Job Started` only.

Live copy measure `[Starts]` now matches original-model job starts on Central
MTD as of 2026-09-21: **217**. Same query on the original model also returns
217. Original dashboard layout was not changed.

## Remaining copy fix

None for date controls. Period and as-of are dropdowns on the copy.
