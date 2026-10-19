# EDW_Gold → dbt analytics map (all domains)

**Date:** 2026-08-19  
**Scope:** Full GBP-Enterprise `EDW_Gold` view layer (37 views), not Finance-only.  
**Target:** dbt project `foundation` → `warehouse_stage.analytics.*` → `lake_house_analytics.operations.*`  
**Rule:** No new `EDW_Gold` / `vw_*` / `dim_*` / `fact_*` names in Foundation Development (D13).

## Contract (2026-08-19)

- Entities are unsuffixed current-row tables (`lot`, `sale`, `job`, `plan`, ...). SCD2 history stays in transform.
- Do **not** publish `*_active` twins. Warehouse wrappers remain for compatibility and are tagged `unpublished` in dbt.
- `det` = repeating line. `obt` = denormalized report row at a named grain. `sum` = pre-agg (period suffix last). `hist` = snapshot/budget.
- Refresh config `model_class`: `entity` (1:1 with transform, thin) vs `report` (joins/reshape owned by BI).
- Do not publish `customer_survey_det`, `customer_survey_test_det`, `pipeline_health_obt`, `sales_det`, `lot_events_det`, or `lot_financials_sum` into the analytics lakehouse.
- Shared presentation store is `lake_house_analytics` (renamed from `lake_house_analytics`). Domain tags stay on refresh (`p_domain`) and folders (`analytics/finance`, etc.).

## Classification (keep / fold / retire)

Every dbt analytics model. Lakehouse publish = row in `control.analytics_refresh_config` with `is_active = 1`.

### Keep (publish)

| Model | Class | Domain | Notes |
|---|---|---|---|
| `calendar` | entity | shared | Gold `vw_dim_date` |
| `company` | entity | shared | Current row (`is_active = 'Y'`) |
| `division` | entity | shared | Current row |
| `operating_unit` | entity | shared | Current row |
| `fiscal_period` | entity | shared | Current row |
| `major_minor` | entity | shared | Current row |
| `plan` | entity | shared | Promoted from Gold `vw_dim_plan_active` |
| `project` | entity | shared | Current row |
| `lot` | entity | shared | Current row |
| `job` | entity | shared | Current row |
| `job_task` | entity | shared | Current row |
| `sale` | entity | shared | Current row |
| `sale_transfer` | entity | shared | Current row |
| `lot_events_obt` | report | operations | Gold `vw_rep_lot_events`; snake_case; OU lookup |
| `lot_obt` | report | operations | 1 row per current lot |
| `sale_obt` | report | operations | Replaces `sales_det` |
| `lot_financials_obt` | report | operations | Wide SGM by lot; replaces `lot_financials_sum` publish |
| `lot_financials_det` | report | operations | Gold `vw_fact_lot_financials` |
| `sales_sum_weekly` | report | operations | OU + week_start + event_type |
| `unit_sum_weekly` | report | operations | OU + week_start |
| `sales_sum_monthly` | report | operations | OU + month_start + event_type |
| `customer_survey_obt` | report | operations | Grain `response_id` |
| `web_listing_obt` | report | operations | Current web scrape snapshot; grain `listing_key`. Not from Gold. |
| `web_community` | entity | operations | Zonda `community` analog from website scrape; grain `community_key`. |
| `web_plan` | entity | operations | Zonda `plans` analog (D13 singular); grain `plan_key`. Not ERP `plan`. |
| `web_lot` | entity | operations | Zonda `lots` analog (D13 singular); grain `lot_key`. Not ERP `lot`. |
| `competitor_listing_obt` | report | operations | Website + mapped GBP ERP listings; grain `listing_key`; side `competitor_web` / `gbp_web` / `gbp_erp`. |
| `competitor_community_obt` | report | operations | Community + side rollup; grain `community_key` + `side`. |
| `general_ledger_det` | report | finance | Gold `vw_fact_general_ledger` |
| `lot_sales_gross_margin_det` | report | finance | Gold `vw_fact_lot_sgm` |
| `sales_gross_margin_map` | entity | finance | Current row |
| `sales_gross_margin_assumptions_det` | report | finance | Full assumptions DET |
| `unit_budget_hist` | report | finance | From Enterprise `UnitBudgets2025` |
| `title_booking_obt` | report | title | Grain `selection_id` |
| `title_communities_det` | report | title | Community map |

**35 published lakehouse tables.**

### Fold (warehouse wrapper only, not published)

| Wrapper | Folds into | Notes |
|---|---|---|
| `company_active` | `company` | `SELECT *` wrapper |
| `division_active` | `division` | |
| `operating_unit_active` | `operating_unit` | |
| `fiscal_period_active` | `fiscal_period` | |
| `major_minor_active` | `major_minor` | |
| `plan_active` | `plan` | |
| `project_active` | `project` | |
| `lot_active` | `lot` | |
| `job_active` | `job` | |
| `job_task_active` | `job_task` | |
| `sale_active` | `sale` | |
| `sales_gross_margin_map_active` | `sales_gross_margin_map` | |
| `lot_financials_active` | `lot_financials_det` | |
| `sales_gross_margin_assumptions_active` | `sales_gross_margin_assumptions_det` | |
| `lot_events_det` | `lot_events_obt` | Gold name leftover |
| `sales_det` | `sale_obt` | Misnamed Gold leftover |
| `lot_financials_sum` | `lot_financials_obt` | Wide Gold aliases only |
| `title_booking_det` | `title_booking_obt` | |

### Retire from lakehouse (warehouse-only or do not rebuild)

| Model | Disposition |
|---|---|
| `customer_survey_det` | Superseded by `customer_survey_obt`. Not published. |
| `customer_survey_test_det` | Dev/test only. Not published. |
| `pipeline_health_obt` | Utilities warehouse-only. Not this lakehouse. |

Leftover unpublished OneLake folders in FD (`*_active`, old names from 11 Aug) are not the publish contract. Do not copy them to Foundation. Optional FD-only drop is a separate instruction.

## How Gold works today (confirmed)

`EDW_Gold` in GBP-Enterprise is mostly a **view layer** over `EDW_Silver` (31 of 37 views are thin cross-database SELECTs). A few materialized tables remain (`dim_*_active`, `rep_lot_events`). FD replaces that layer with **dbt analytics views** over `transform.*`, then materializes into `lake_house_analytics` for all domains.

## Consumers (snapshots, confirmed)

| Workspace | Example models using Gold / vw_* shapes |
|---|---|
| Finance / Finance-Dev | Executive Dashboard, Executive Unit Dashboard, Weekly Unit Report variants |
| Audit-Dev | Executive Unit Dashboard |
| GBP-Enterprise / Dev | CustomerSatisfactionSurveyResults_* |
| Operations | EDW_Gold lakehouse + CustSat (legacy) |

## Complete map (37 Gold views)

| EDW_Gold view | dbt / analytics target | Domain tag | Lakehouse |
|---|---|---|---|
| `vw_dim_date` | `calendar` | shared | yes |
| `vw_dim_company` | `company` | shared | yes |
| `vw_dim_company_active` | `company` (folded) | shared | no (wrapper only) |
| `vw_dim_division` | `division` | shared | yes |
| `vw_dim_division_active` | `division` (folded) | shared | no (wrapper only) |
| `vw_dim_operating_unit` | `operating_unit` | shared | yes |
| `vw_dim_operating_unit_active` | `operating_unit` (folded) | shared | no (wrapper only) |
| `vw_dim_period` | `fiscal_period` | shared | yes |
| `vw_dim_period_active` | `fiscal_period` (folded) | shared | no (wrapper only) |
| `vw_dim_major_minor` | `major_minor` | shared | yes |
| `vw_dim_major_minor_active` | `major_minor` (folded) | shared | no (wrapper only) |
| `vw_dim_plan_active` | `plan` | shared | yes |
| `vw_dim_project` | `project` | shared | yes |
| `vw_dim_project_active` | `project` (folded) | shared | no (wrapper only) |
| `vw_dim_lot` | `lot` | shared | yes |
| `vw_dim_lot_active` | `lot` (folded) | shared | no (wrapper only) |
| `vw_dim_job` | `job` | shared | yes |
| `vw_dim_job_active` | `job` (folded) | shared | no (wrapper only) |
| `vw_dim_job_task` | `job_task` | shared | yes |
| `vw_dim_job_task_active` | `job_task` (folded) | shared | no (wrapper only) |
| `vw_dim_sale` | `sale` | shared | yes |
| `vw_dim_sale_active` | `sale` (folded) | shared | no (wrapper only) |
| `vw_dim_sale_transfer` | `sale_transfer` | shared | yes |
| `vw_dim_sgm_map` | `sales_gross_margin_map` | finance | yes |
| `vw_dim_sgm_map_active` | `sales_gross_margin_map` (folded) | finance | no (wrapper only) |
| `vw_fact_general_ledger` | `general_ledger_det` | finance | yes |
| `vw_fact_lot_financials` | `lot_financials_det` | operations | yes |
| `vw_fact_lot_financials_active` | `lot_financials_det` (folded) | operations | no (wrapper only) |
| `vw_fact_lot_sgm` | `lot_sales_gross_margin_det` | finance | yes |
| `vw_fact_sgm_assumptions_active` | `sales_gross_margin_assumptions_det` | finance | yes |
| `vw_rep_lot_events` | `lot_events_obt` | operations | yes |
| `vw_rep_lot_financials_summary` | `lot_financials_obt` | operations | yes |
| `vw_rep_sales` | `sale_obt` | operations | yes |
| `vw_rep_customersurvey` | `customer_survey_obt` | operations | no (superseded) |
| `vw_rep_customersurvey_test` | (not published) | operations | no |
| `vw_rep_title_booking` | `title_booking_obt` | title | yes |
| `vw_rep_title_communities` | `title_communities_det` | title | yes |

## FD-only analytics (not Gold views)

| Target | Notes |
|---|---|
| `customer_survey_obt` | CustSat OBT rebuild; grain `response_id` |
| `customer_survey_response_statistical_det` | Rating enrichment; grain `response_id` |
| `customer_survey_statistical_sum` | Peer benchmarks and z-scores |
| `customer_survey_statistical_det` | Period-over-period significance detail |
| `customer_survey_comment_det` | VOC enriched comments; grain `source_comment_id` |
| `customer_survey_theme_det` | Comment x theme assignments |
| `customer_survey_voc_sum` | VOC sentiment/theme aggregates |
| `customer_survey_voc_review_det` | Human review queue |
| `lot_obt` | 1 row per current lot + project + OU + current sale + current job |
| `sale_obt` | 1 row per current sale; replaces misnamed `sales_det` |
| `lot_financials_obt` | Wide SGM by lot (snake_case) |
| `sales_sum_weekly` | OU + week_start + event_type |
| `unit_sum_weekly` | OU + week_start; inventory on `is_current_week` only |
| `sales_sum_monthly` | OU + month_start + event_type; budget grain |
| `unit_budget_hist` | From `EDW_Silver.dbo.UnitBudgets2025` |
| `pipeline_health_obt` | Utilities only; not published to analytics lakehouse |

## Refresh

- Config: [`automation/sql/analytics_refresh_config.sql`](../../automation/sql/analytics_refresh_config.sql)
- Pipeline: `pipeline_operations_analytics_refresh` with `p_domain` = `shared` \| `operations` \| `finance` \| `title` \| **`all`**
- Deploy views when ODBC unavailable: [`dbt/deploy_via_sql_runner.sh`](../../dbt/deploy_via_sql_runner.sh)
- SM rebind after table rename: [`automation/rebind_analytics_sms.py`](../../automation/rebind_analytics_sms.py)

## Non-goals

- Do not recreate `EDW_Gold` warehouse in FD
- Do not 1:1 clone Enterprise presentation SMs; rebind domain reports to these lakehouse tables when each domain moves
- Do not publish a GL OBT, job_task DET clone, or per-domain lakehouses in this pass
- Do not turn on 15-minute analytics refresh unless a named window says so
