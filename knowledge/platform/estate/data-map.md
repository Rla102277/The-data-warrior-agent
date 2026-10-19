# Foundation Development data map

**Captured:** 2026-10-16 via `fab ls` on warehouse/lakehouse Tables paths  
**Raw dump:** [`../inventory/fd-warehouse-tables-2026-10-16.txt`](../inventory/fd-warehouse-tables-2026-10-16.txt)

## warehouse_stage schemas

| Schema | Table count (approx) | Status |
|---|---|---|
| `control` | 31 | Populated — metadata, audit, web scrape, CustSat VOC |
| `transform` | 22 | Populated — conformed entities + hist |
| `raw` | 3 | Web landing: `web_page_det`, `web_listing_det`, `web_aggregator_det` |
| `analytics` | 1 | `customer_survey_voc_comment_stage` only |
| `dbo` | 0 | Empty (good) |
| `stage` | **missing** | Path NotFound — no `Tables/stage` |

### control (Confirmed full list)

`_verify_counts`, `analytics_refresh_config`, `audit_orchestrator_control`, `audit_pipeline_control`, `audit_sp_control`, `audit_step_control`, `azure_vs_mirrored_db_audit_log`, `column_validation`, `customer_survey_question_scale_map`, `customer_survey_statistical_config`, `customer_survey_theme_map`, `customer_survey_voc_config`, `customer_survey_voc_exception_det`, `customer_survey_voc_review`, `customer_survey_voc_run_det`, `dev_validate_counts`, `parity_check`, `row_validation`, `stage_load_config`, `web_community_geo`, `web_community_project_map`, `web_competitor_peer`, `web_gbp_builder`, `web_peer_project`, `web_project_vt_peer`, `web_scrape_adapter`, `web_scrape_defer_det`, `web_scrape_heartbeat_det`, `web_scrape_queue`, `web_scrape_run_det`, `web_scrape_source`

### transform (Confirmed full list)

`calendar`, `company`, `division`, `fiscal_period`, `general_ledger_det`, `job`, `job_task`, `lot`, `lot_financials_det`, `lot_financials_hist`, `lot_sales_gross_margin_det`, `lot_sales_gross_margin_hist`, `major_minor`, `milestone`, `operating_unit`, `project`, `sale`, `sale_transfer`, `sales_gross_margin_assumptions_det`, `sales_gross_margin_assumptions_hist`, `sales_gross_margin_map`, `unit_budget_hist`

## lake_house_analytics.operations

~77 tables (Confirmed). Includes:

- Core dimensions/entities and `*_active` views/tables
- Sales / lot financials / SGM / unit marts (`sales_sum_weekly`, `unit_sum_weekly`, etc.)
- Customer survey / VOC family
- Lot events, title booking
- Web + market intelligence family including D19 `market_dim_*` names
- Calendar, company, division, project, plan, operating_unit

Schemas under lakehouse Tables: `dbo`, `operations` (Confirmed). Consumption lives under `operations`.

## Interpretation for engineers

1. **Control plane is real** — `stage_load_config` and audit_* tables are the D10 story.
2. **Transform holds the EDW port** — hist tables present (D14 pattern).
3. **Analytics consumption is mostly in the lakehouse**, not `warehouse_stage.analytics`.
4. **Documented `stage` schema is not materialized as tables** in this inventory. Treat "stage" as load orchestration until proven otherwise with SQL against hidden objects.

## Not yet inventoried this pass

- Row counts / freshness (needs SQL queries)
- Proc inventory in warehouse_stage
- Salesforce warehouse tables
- OneLake Files layout under lakehouses
- Shortcut definitions for dataverse_gbpdev
