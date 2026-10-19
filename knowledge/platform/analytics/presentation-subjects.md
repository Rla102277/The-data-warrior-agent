# Presentation subjects inventory (consumption rebuilds)

**Date:** 2026-08-12  
**Purpose:** Rank remaining Enterprise presentation subjects for Foundation rebuild (plan Phase 3 / scorecard B-).  
**Rule:** Additive rebuild only (D12). No Enterprise cutover.

## Already rebuilt in Foundation (D13)

| Subject | Foundation artifacts | Pattern |
|---|---|---|
| Customer satisfaction | `semantic_model_operations_customer_survey`, `report_operations_customer_survey`, `customer_survey_obt` | OBT + SM + report (Detail page 2026-08-25) |
| Finance Executive | `semantic_model_finance_executive_dashboard`, report | `lot_events_obt` + calendar / operating_unit / project / lot |
| Finance Executive Unit | `semantic_model_finance_executive_unit_dashboard`, report | Lakehouse bind |
| Weekly Sales (Optimized) | `semantic_model_finance_weekly_sales`, report | From Finance-Dev |
| Weekly Unit (Optimized) | `semantic_model_finance_weekly_unit`, report | From Finance-Dev |
| Title booking / communities | `semantic_model_title_booking`, `title_booking_obt`, `title_communities_det` | OBT + SM (owner committed 2026-08-12) |
| Lot events / starts-completions | `semantic_model_operations_lot_events`, `report_operations_lot_events`, `lot_events_obt` | OBT + SM + report |
| Sales detail / pipeline | `semantic_model_operations_sales`, `report_operations_sales`, `sale_obt` | OBT + SM + report |
| Web listings | `semantic_model_operations_web_listings`, `report_operations_web_listings`, `web_listing_obt` | Current scrape snapshot + inventory map (PPSF 2026-08-26) |
| Competitor analysis | `semantic_model_operations_competitor_analysis`, `report_operations_competitor_analysis`, `competitor_listing_obt` / `competitor_community_obt` | Website vs GBP ERP at mapped communities |
| **Foundation Market Intelligence** | `semantic_model_operations_market_intelligence`, `report_operations_market_intelligence` | Product app: Community Brief, Peer Arena, What Moved, Inventory, Coverage (MVP 2026-09-15) |

## Remaining subjects (inventory)

Ranked for rebuild priority. Evidence: workspace maps + prior CDO review ("Other presentation ~10-12").

| Rank | Subject | Legacy home | Why next | Suggested Foundation pattern |
|---:|---|---|---|---|
| 1 | Finance Weekly Light / Hybrid variants | Finance-Dev | Lower priority than Optimized pair already copied | Defer unless business rejects Optimized |
| 2 | Finance paginated Fast Weekly Sales/Unit | Finance-Dev | Paginated RDL; different stack | Defer; keep on Finance until capacity for RDL rebuild |
| 3 | CustSatReport (legacy non-OBT) | Finance-Dev / Operations | Superseded by OBT CustSat | Do not rebuild; retire at cutover |
| 4 | Report Usage Metrics | Finance-Dev | Admin telemetry | Utilities folder later; not domain analytics |
| 5 | Operations RTI / Eventhouse samples | Operations (`RTISample.*`) | Real-time, separate capacity story | Out of scope for analytics lakehouse tranche |
| 6 | Audit Executive Unit clone | Audit-Dev | Clone of Finance Exec Unit | Stayed in Audit-Dev on 2026-08-20 (not copied to Foundation Governance). Rebound to Foundation SM at cutover; no separate rebuild |
| 7 | Best-practice analyzer notebook | Finance-Dev | Dev tooling | Skip |

## Recommended next 2-3 rebuilds

**Built in FD 2026-08-12** via [`automation/build_presentation_subjects.py`](../../automation/build_presentation_subjects.py):

| Subject | Artifacts | FD IDs |
|---|---|---|
| Lot events | `semantic_model_operations_lot_events`, `report_operations_lot_events` | `6fa181c9-…`, `1016c74b-…` |
| Title | `semantic_model_title_booking` (thin; booking + communities) | `ea07c490-…` |
| Ops sales | `semantic_model_operations_sales`, `report_operations_sales` | `1fe439f5-…`, `8a3102db-…` |
| Web listings | `semantic_model_operations_web_listings`, `report_operations_web_listings` | `a5893487-…`, `79c9e17e-…` |
| Competitor analysis | `semantic_model_operations_competitor_analysis`, `report_operations_competitor_analysis` | `116ecabc-…`, `8079c0ec-…` (2026-08-26) |

Bound to Foundation Development Lake (`86e291b0-…`). Refresh only after hydration has data. Promote with next wave when ready.

**2026-08-12 analytics contract:** `*_active` twins are not published. Lot events SM binds `lot_events_obt` (M renames snake_case back to Gold names for existing DAX). Title SM binds `title_booking_obt`. Ops sales SM binds `sale_obt`. Weekly SMs keep event-level DAX on `lot_events_obt` and gain `sales_sum_weekly` / `unit_sum_weekly` / `sales_sum_monthly` tables.

Do not enable schedules until Phase 3 hydration has Foundation twin data.

## Non-goals

- 1:1 clone of every Finance-Dev Light/Hybrid variant
- RTI / KQL sample estate
- Paginated RDL migration in this tranche
