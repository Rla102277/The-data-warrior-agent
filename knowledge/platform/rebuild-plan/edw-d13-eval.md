# EDW_Silver + EDW_Gold complete D13 evaluation (Build 4a)

**Date:** 2026-08-11  
**Method:** `automation/edw_d13_eval.py` - read-only pulls of `sys.objects`, `sys.sql_modules`, and `sys.columns` from the GBP-Enterprise SQL endpoint (EDW_Silver, EDW_Gold) and the Foundation Development endpoint (`warehouse_stage`, `lake_house_analytics`). Legacy definitions are normalized through the D13 rename map and token-diffed against the deployed FD objects. Nothing in Enterprise was renamed or altered (D12 respected).  
**Layer rule (user-confirmed 2026-08-11):** Silver objects live in `stage`/`transform` (plus `control` for the audit plane); Gold objects live in `analytics`.  
**Raw evidence:** `/tmp/edw_eval/results.json` and `/tmp/edw_eval/diffs/` (regenerate any time by rerunning the script).

## Verdict

**All 104 legacy objects are accounted for: 102 rebuilt and verified under D13 names in Foundation Development, 2 delete-at-cutover by design.** No missing objects. No unexplained definition drift. Every difference found is either an intentional improvement made during the port or a benign platform default. Follow-up items are listed at the end; none block parity work.

| Layer | Objects | Rebuilt + verified | Delete at cutover |
|---|---|---|---|
| EDW_Silver `dbo` procs | 21 | 21 | 0 |
| EDW_Silver `dbo` tables | 24 | 22 | 2 (`dim_job_task1`, `dim_job_task2`) |
| EDW_Silver `control` | 14 | 14 | 0 |
| EDW_Gold views | 37 | 37 | 0 |
| EDW_Gold `dbo` tables | 8 | 8 (superseded by lakehouse) | 0 (originals die at cutover) |
| **Total** | **104** | **102** | **2** |

## How sources are read (confirmed, corrects an earlier assumption)

FD `warehouse_stage` has **empty `raw` and `stage` schemas**. The transform procs read mirrored sources cross-database exactly as the EDW procs do (`HBLive.*`, `SPLive.dbo.*`, `BuildPro.dbo.*`, `dataverse_gbpdev.*`), resolved inside the FD workspace via shortcut lakehouses of the same names. This is identical reference-for-reference with EDW_Silver, so it verifies cleanly - but it means the `stage` layer is a pass-through by shortcut, not a copy. If a physical stage copy is ever wanted, that is a separate design decision.

## 1. EDW_Silver `dbo` procedures (21) -> `warehouse_stage.transform`

Verification: definitions token-diffed after remapping `EDW_Silver.dbo.<obj>` -> `transform.<new>` and audit-literal proc names. **Identical** = zero tokens differ after remap.

| # | EDW_Silver | FD target | Verification |
|---|---|---|---|
| 1 | `dbo.sp_clear_tables` | `transform.sp_clear_tables` | Identical |
| 2 | `dbo.sp_load_dim_company` | `transform.sp_load_company` | Identical |
| 3 | `dbo.sp_load_dim_date` | `transform.sp_load_calendar` | Identical logic; FD adds `@LoadType`, `@AuditID`, `@OrchestratorAuditID` params so the orchestrator can call every proc uniformly (intentional) |
| 4 | `dbo.sp_load_dim_division` | `transform.sp_load_division` | Identical |
| 5 | `dbo.sp_load_dim_job` | `transform.sp_load_job` | Identical except dead target join removed (see F2) |
| 6 | `dbo.sp_load_dim_job_task` | `transform.sp_load_job_task` | Identical except dead target join removed (F2) |
| 7 | `dbo.sp_load_dim_lot` | `transform.sp_load_lot` | Identical except dead target join removed (F2) |
| 8 | `dbo.sp_load_dim_major_minor` | `transform.sp_load_major_minor` | Identical |
| 9 | `dbo.sp_load_dim_operating_unit` | `transform.sp_load_operating_unit` | Identical except dead target join removed (F2) |
| 10 | `dbo.sp_load_dim_period` | `transform.sp_load_fiscal_period` | Identical |
| 11 | `dbo.sp_load_dim_project` | `transform.sp_load_project` | Identical except dead target join removed (F2) |
| 12 | `dbo.sp_load_dim_sale` | `transform.sp_load_sale` | Identical except dead target join removed (F2) |
| 13 | `dbo.sp_load_dim_sale_transfer` | `transform.sp_load_sale_transfer` | Identical except dead target join removed (F2) |
| 14 | `dbo.sp_load_dim_sgm_map` | `transform.sp_load_sales_gross_margin_map` | Identical |
| 15 | `dbo.sp_load_fact_general_ledger` | `transform.sp_load_general_ledger_det` | Identical except dead target join removed (F2) |
| 16 | `dbo.sp_load_fact_lot_financials` | `transform.sp_load_lot_financials_det` | Identical |
| 17 | `dbo.sp_load_fact_lot_financials_hist` | `transform.sp_load_lot_financials_hist` | Identical |
| 18 | `dbo.sp_load_fact_lot_sgm` | `transform.sp_load_lot_sales_gross_margin_det` | Identical |
| 19 | `dbo.sp_load_fact_lot_sgm_hist` | `transform.sp_load_lot_sales_gross_margin_hist` | Identical |
| 20 | `dbo.sp_load_fact_sgm_assumptions` | `transform.sp_load_sales_gross_margin_assumptions_det` | Identical |
| 21 | `dbo.sp_load_fact_sgm_assumptions_hist` | `transform.sp_load_sales_gross_margin_assumptions_hist` | Identical |

Note: several procs keep legacy names for **internal CTEs and temp tables** (`dim_job AS (...)`, `#PREP_01_dim_project`, `dim_sgm_map` CTE). These are not schema objects; the D13 ban applies to catalog objects only. Cosmetic cleanup is optional.

## 2. EDW_Silver `dbo` tables (24) -> `warehouse_stage.transform`

Verification: `sys.columns` compared column-by-column in ordinal order (name, type, length, precision, scale, nullability).

| # | EDW_Silver | FD target | Columns | Verification |
|---|---|---|---|---|
| 1 | `dbo.dim_company` | `transform.company` | 22/22 | Names+order exact; datetime2(3)->(6) only (F1) |
| 2 | `dbo.dim_date` | `transform.calendar` | 22/22 | Names+order exact; F1 |
| 3 | `dbo.dim_division` | `transform.division` | 17/17 | Names+order exact; F1 |
| 4 | `dbo.dim_job` | `transform.job` | 25/25 | Names+order exact; F1 |
| 5 | `dbo.dim_job_task` | `transform.job_task` | 35/35 | Names+order exact; F1 |
| 6 | `dbo.dim_job_task1` | - | - | **DELETE at cutover** (abandoned copy) |
| 7 | `dbo.dim_job_task2` | - | - | **DELETE at cutover** (abandoned copy) |
| 8 | `dbo.dim_lot` | `transform.lot` | 49/49 | Names+order exact; F1 |
| 9 | `dbo.dim_major_minor` | `transform.major_minor` | 18/18 | Names+order exact; F1 |
| 10 | `dbo.dim_operating_unit` | `transform.operating_unit` | 25/25 | Names+order exact; F1 |
| 11 | `dbo.dim_period` | `transform.fiscal_period` | 16/16 | Names+order exact; F1 |
| 12 | `dbo.dim_project` | `transform.project` | 41/41 | Names+order exact; F1 |
| 13 | `dbo.dim_sale` | `transform.sale` | 67/67 | Names+order exact; F1 |
| 14 | `dbo.dim_sale_transfer` | `transform.sale_transfer` | 14/14 | Names+order exact; F1 |
| 15 | `dbo.dim_sgm_map` | `transform.sales_gross_margin_map` | 20/20 | Names+order exact; F1 |
| 16 | `dbo.fact_general_ledger` | `transform.general_ledger_det` | 29/29 | Names+order exact; F1 |
| 17 | `dbo.fact_lot_financials` | `transform.lot_financials_det` | 17/17 | Names+order exact; F1 |
| 18 | `dbo.fact_lot_financials_hist` | `transform.lot_financials_hist` | 21/21 | Names+order exact; F1 |
| 19 | `dbo.fact_lot_sgm` | `transform.lot_sales_gross_margin_det` | 26/26 | Names+order exact; F1 |
| 20 | `dbo.fact_lot_sgm_hist` | `transform.lot_sales_gross_margin_hist` | 30/30 | Names+order exact; F1 |
| 21 | `dbo.fact_sgm_assumptions` | `transform.sales_gross_margin_assumptions_det` | 25/25 | Names+order exact; F1 |
| 22 | `dbo.fact_sgm_assumptions_hist` | `transform.sales_gross_margin_assumptions_hist` | 29/29 | Names+order exact; F1 |
| 23 | `dbo.tbl_Milestones` | `transform.milestone` | 100% | **Exact match** incl. types |
| 24 | `dbo.UnitBudgets2025` | `transform.unit_budget_hist` | 4/4 | Names+order exact; FD tightened 3 columns to NOT NULL (stricter, fine) |

**Producer decisions (closes the open question):**

- `transform.milestone`: static reference copy; no load proc exists in Enterprise either. Disposition: **static, reload manually if the business ever changes milestones**. No `sp_load_` stub - a proc with no source to read from is noise.
- `transform.unit_budget_hist`: manual harvest from `EDW_Silver.dbo.UnitBudgets2025` (decided 2026-08-10, 1008 rows). Disposition: **manual refresh**; revisit only if a budgets source system materializes.

## 3. EDW_Silver `control` (14) -> `warehouse_stage.control`

| # | EDW_Silver | FD target | Verification |
|---|---|---|---|
| 1 | `control.sp_audit_start` | same name | Identical |
| 2 | `control.sp_audit_end` | same name | Identical |
| 3 | `control.sp_audit_cleanup` | same name | Identical |
| 4 | `control.sp_update_audit_control` | same name | Identical |
| 5 | `control.sp_compare_azure_vs_mirrored_db` | same name | Identical |
| 6-12 | `audit_orchestrator_control`, `audit_pipeline_control`, `audit_sp_control`, `audit_step_control`, `azure_vs_mirrored_db_audit_log`, `column_validation`, `row_validation` | same names | Present in FD `control` |
| 13 | `control.vw_pipeline_performance_summary` | `control.pipeline_performance_sum` | Identical |
| 14 | `control.vw_sp_performance_summary` | `control.sp_performance_sum` | Identical |

The earlier rename-map gap ("5 control procs unmapped") is closed: they carry no banned prefixes, keep their names, and are definition-verified.

## 4. EDW_Gold views (37) -> dbt `warehouse_stage.analytics.*`

Verification: definitions token-diffed after remapping `EDW_Silver.dbo.*` -> `transform.*` and view headers. All 37 have a dbt model file of the same target name in `dbt/models/analytics/` (dbt `config()` + `source()` macros confirmed - dbt owns the layer; 39 model files total including the two FD-only models).

**35 of 37: token-identical.** The two exceptions, both intentional or cosmetic:

| EDW_Gold | FD target | Verification |
|---|---|---|
| `vw_rep_lot_events` | `analytics.lot_events_det` | Logic identical; FD **adds** an `ounit` column (hardcoded operating-unit code -> short-name map). Enhancement; see F4 |
| `vw_rep_sales` | `analytics.sales_det` | Definitions identical. Gold's catalog metadata is stale (missing `sale_guid`, `is_deleted` that its own `SELECT s1.*` now returns; Enterprise view was never refreshed after `dim_sale` gained columns). FD is correct; nothing to do on our side (D12: we do not touch Enterprise) |

Full name map (all verified): `vw_dim_date`->`calendar`, `vw_dim_company`->`company`, `vw_dim_company_active`->`company_active`, `vw_dim_division`->`division`, `vw_dim_division_active`->`division_active`, `vw_dim_operating_unit`->`operating_unit`, `vw_dim_operating_unit_active`->`operating_unit_active`, `vw_dim_period`->`fiscal_period`, `vw_dim_period_active`->`fiscal_period_active`, `vw_dim_major_minor`->`major_minor`, `vw_dim_major_minor_active`->`major_minor_active`, `vw_dim_plan_active`->`plan_active`, `vw_dim_project`->`project`, `vw_dim_project_active`->`project_active`, `vw_dim_lot`->`lot`, `vw_dim_lot_active`->`lot_active`, `vw_dim_job`->`job`, `vw_dim_job_active`->`job_active`, `vw_dim_job_task`->`job_task`, `vw_dim_job_task_active`->`job_task_active`, `vw_dim_sale`->`sale`, `vw_dim_sale_active`->`sale_active`, `vw_dim_sale_transfer`->`sale_transfer`, `vw_dim_sgm_map`->`sales_gross_margin_map`, `vw_dim_sgm_map_active`->`sales_gross_margin_map_active`, `vw_fact_general_ledger`->`general_ledger_det`, `vw_fact_lot_financials`->`lot_financials_det`, `vw_fact_lot_financials_active`->`lot_financials_active`, `vw_fact_lot_sgm`->`lot_sales_gross_margin_det`, `vw_fact_sgm_assumptions_active`->`sales_gross_margin_assumptions_active`, `vw_rep_lot_events`->`lot_events_det`, `vw_rep_lot_financials_summary`->`lot_financials_sum`, `vw_rep_sales`->`sales_det`, `vw_rep_customersurvey`->`customer_survey_det`, `vw_rep_customersurvey_test`->`customer_survey_test_det`, `vw_rep_title_booking`->`title_booking_det`, `vw_rep_title_communities`->`title_communities_det`.

## 5. EDW_Gold `dbo` tables (8) -> `lake_house_analytics.operations.*`

The legacy materialized tables (producer never identified, P10) are superseded by lakehouse materializations produced by `pipeline_operations_analytics_refresh`. All 8 verified present:

| EDW_Gold table | Lakehouse replacement | Status |
|---|---|---|
| `dbo.dim_company` | `operations.company` | Present |
| `dbo.dim_date` | `operations.calendar` | Present |
| `dbo.dim_lot_active` | `operations.lot_active` | Present |
| `dbo.dim_operating_unit_active` | `operations.operating_unit_active` | Present |
| `dbo.dim_period_active` | `operations.fiscal_period_active` | Present |
| `dbo.dim_project_active` | `operations.project_active` | Present |
| `dbo.dim_sale_active` | `operations.sale_active` | Present |
| `dbo.rep_lot_events` | `operations.lot_events_det` | Present |

The P10 producer mystery is now moot: FD has a named, scheduled producer. The legacy tables die at cutover.

## Findings and follow-ups

- **F1 - datetime2 precision (benign):** 83 columns across 20 transform tables are `datetime2(3)` in EDW and `datetime2(6)` in FD (Fabric Warehouse default). Lossless widening; no action. Parity checks must compare timestamps at millisecond precision.
- **F2 - dead target join removed (intentional, watch in parity):** 8 procs (`job`, `job_task`, `lot`, `operating_unit`, `project`, `sale`, `sale_transfer`, `general_ledger_det`) dropped an unused `LEFT JOIN <target> tgt ... is_active = 'Y'` from a `SELECT src.* INTO #prep` step. The join contributed no columns; in EDW it could theoretically fan out rows if duplicate active target rows existed. FD's version is the fix. If row-count parity vs Enterprise ever differs on these entities, this is the first suspect - it would mean Enterprise was double-counting.
- **F3 - `sp_load_calendar` signature (intentional):** FD adds audit parameters so all 21 procs share a uniform orchestrator contract.
- **F4 - `lot_events_det` `ounit` map (tech debt):** the added column hardcodes 9 operating-unit codes in the view. Should become a lookup against `transform.operating_unit` or a seed table in a later dbt pass.
- **F5 - lakehouse backup-table explosion (action needed, still growing):** see the full investigation below.
- **F6 - stage layer is shortcuts, not copies:** FD `raw`/`stage` schemas are empty; procs read shortcut lakehouses (`HBLive`, `SPLive`, `BuildPro`, `dataverse_gbpdev`) cross-database, same as EDW reads its mirrored DBs. Works and verifies cleanly; documented here so nobody assumes a physical stage copy exists.
- **F7 - Enterprise hygiene (cutover-day list, do not touch now):** `dim_job_task1`, `dim_job_task2`, the empty uppercase `CONTROL` schema, and the empty `stage` schema in EDW_Silver (confirmed empty on 2026-08-11); plus Gold's stale `vw_rep_sales` metadata.

## F5 in full: analytics lakehouse backup-table explosion (investigated 2026-08-11 ~11:30 CDT)

**State:** `lake_house_analytics.operations` in Foundation Development holds **3,302 orphaned `*_backup_<guid>` tables** next to the 39 real ones (3,341 total), and the count is still climbing - it grew by 19 during this investigation. The **Foundation twin is clean** (0 tables; its refresh never ran and its schedules stay off).

**Mechanism (confirmed from the live pipeline definition):** `pipeline_operations_analytics_refresh` is a Lookup over `control.analytics_refresh_config` feeding a ForEach of Copy activities. The Copy sink is `LakehouseTableSink` with `tableActionOption: "Overwrite"`. Fabric implements that overwrite by writing the new table and renaming the previous delta table to `<table>_backup_<guid>` - and it leaves the backup behind on every run. Every refresh therefore leaves 39 new orphan tables.

**Cadence (confirmed from job schedules and `sys.objects.create_date`):** the pipeline has **two enabled schedules** - a 15-minute cron (created 2026-08-06, owner personal account) and a daily 06:30 UTC run (created 2026-08-10). Backup creation runs at ~156/hour (39 tables x 4 runs) continuously since the first full publish on 2026-08-10 17:00 UTC, pausing only during the 2026-08-11 ~14:00 UTC capacity incident when jobs were cancelled, and resuming when FD schedules were re-enabled. The 06:00 UTC hour shows 193 creations - both schedules firing. That is **~3,744 orphan tables per day** at the current rate.

**Cost:** the 39 tables hold ~55M rows (largest: `general_ledger_det` 25.9M, `job_task` 11.2M, `job_task_active` 6.9M, `lot_financials_det`/`_active` 3.5M each). Every 15 minutes the pipeline re-reads all of it from `warehouse_stage` and rewrites it to delta - roughly 5.3B rows of copy volume per day on the shared F32 - and each run's leftover backups are a complete physical copy of all 39 tables, so OneLake storage grows by one full dataset copy per run.

**Reliability symptom (observed live):** 10 of the 39 base tables (`calendar`, `company`, `company_active`, `customer_survey_det`, `customer_survey_obt`, `customer_survey_test_det`, `division`, `division_active`, `fiscal_period`, `fiscal_period_active`) currently fail SQL endpoint queries with *"the underlying location does not exist"* - the endpoint's metadata sync cannot keep up with a table being swapped every 15 minutes, so it points at parquet files the last overwrite already removed. Any consumer reading through the SQL endpoint hits intermittent failures. These windows recur on every run until the churn stops.

**Remediation (recommended order):**

1. **Stop the bleeding: DONE 2026-08-11 ~11:30 CDT.** Per the standing "FD is build-only, nothing runs" direction, **all three** enabled FD schedules were disabled (stage orchestrator 15-min cron, analytics refresh 15-min cron, analytics refresh daily 06:30 UTC) and one in-flight analytics refresh run was cancelled. Verified after the change: zero enabled schedules on any pipeline, semantic model, or dbt job in either Foundation Development or Foundation. Re-enable deliberately, off-hours, when hydration is approved.
2. **One-time purge: DONE 2026-08-11 ~11:45 CDT.** All **3,339** backup folders deleted via OneLake DFS API (guarded: suffix regex `_backup_<guid>`; the keep-list was verified to be exactly the 39 real tables before deletion). 3,339 deleted, 0 errors; OneLake listing confirmed 39 directories remain. FD-only; Foundation had nothing to purge.
3. **Durable fix: DONE 2026-08-11.** New notebook `notebook_operations_backup_cleanup` (source checked in at `automation/notebooks/notebook_operations_backup_cleanup.py`) removes any `operations.*_backup_<guid>` folders; it resolves `lake_house_analytics` by name, so it works unchanged when promoted to Foundation. Wired into `pipeline_operations_analytics_refresh` as a final `cleanup_backup_tables` activity (runs after the ForEach succeeds). Smoke run completed successfully. Foundation's pipeline copy picks this up at the next deployment-pipeline promote.
4. **Verify: DONE 2026-08-11.** SQL endpoint metadata refresh triggered via API; all 10 previously broken tables query cleanly again, and the endpoint catalog shows exactly 39 tables and 0 backups.

## Supersedes

This document supersedes the per-object status implied in [rename-map.md](rename-map.md) sections 1-2 and closes rename-map gap 1 (views fully enumerated and verified) and the P10 producer question for Gold's materialized tables.
