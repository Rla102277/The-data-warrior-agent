# Authoritative rename map (decision D7 input)

**Documented:** 2026-08-04  
**Source of truth:** live OneLake table listing via `fab ls` on 2026-08-04 (Confirmed), proc names from `pipelines/edw-deep-dive.md` (Confirmed from pipeline definitions)  
**Standard applied:** `rearchitecture.md` section 2 (raw / stage / analytics; no dim_ / fact_ / vw_ prefixes; obt / sum / det / hist / map shape markers; period suffix last)  
**Status:** Draft for team sign-off. Names are permanent once approved.  
**2026-08-11:** Per-object verification status now lives in [edw-d13-eval.md](edw-d13-eval.md) (104/104 objects evaluated; supersedes the status implied in sections 1-2 below).

Seed script for `control.stage_load_config` lives at `automation/sql/stage_load_config.sql` and mirrors this map exactly.

---

## 1. Transform layer: `EDW_Silver.dbo` becomes `wh_stage.transform`

Warehouse schemas (no `dbo` for business objects):

| Schema | Role |
|---|---|
| `raw` | Landing / mirrored source shapes |
| `stage` | Staging / prep before conform |
| `control` | Audit, config, orchestration metadata |
| `transform` | Conformed entities and details (former silver) |
| `analytics` | Consumption views and models (former gold) |

### 1.1 Reference entities (former dimensions, plain names, no shape marker)

| Current table | Target table | Current proc | Target proc | Notes |
|---|---|---|---|---|
| `dbo.dim_company` | `transform.company` | `dbo.sp_load_dim_company` | `transform.sp_load_company` | |
| `dbo.dim_date` | `transform.calendar` | `dbo.sp_load_dim_date` | `transform.sp_load_calendar` | Activated in Foundation Development |
| `dbo.dim_division` | `transform.division` | `dbo.sp_load_dim_division` | `transform.sp_load_division` | |
| `dbo.dim_job` | `transform.job` | `dbo.sp_load_dim_job` | `transform.sp_load_job` | |
| `dbo.dim_job_task` | `transform.job_task` | `dbo.sp_load_dim_job_task` | `transform.sp_load_job_task` | |
| `dbo.dim_lot` | `transform.lot` | `dbo.sp_load_dim_lot` | `transform.sp_load_lot` | |
| `dbo.dim_major_minor` | `transform.major_minor` | `dbo.sp_load_dim_major_minor` | `transform.sp_load_major_minor` | REVIEW: confirm major/minor meaning |
| `dbo.dim_operating_unit` | `transform.operating_unit` | `dbo.sp_load_dim_operating_unit` | `transform.sp_load_operating_unit` | |
| `dbo.dim_period` | `transform.fiscal_period` | `dbo.sp_load_dim_period` | `transform.sp_load_fiscal_period` | REVIEW: assumes period = fiscal period |
| `dbo.dim_project` | `transform.project` | `dbo.sp_load_dim_project` | `transform.sp_load_project` | |
| `dbo.dim_sale` | `transform.sale` | `dbo.sp_load_dim_sale` | `transform.sp_load_sale` | |
| `dbo.dim_sale_transfer` | `transform.sale_transfer` | `dbo.sp_load_dim_sale_transfer` | `transform.sp_load_sale_transfer` | |
| `dbo.dim_sgm_map` | `transform.sales_gross_margin_map` | `dbo.sp_load_dim_sgm_map` | `transform.sp_load_sales_gross_margin_map` | REVIEW: SGM expansion |

### 1.2 Transaction and history tables (former facts)

| Current table | Target table | Current proc | Target proc | Run group |
|---|---|---|---|---|
| `dbo.fact_general_ledger` | `transform.general_ledger_det` | `dbo.sp_load_fact_general_ledger` | `transform.sp_load_general_ledger_det` | standard |
| `dbo.fact_lot_financials` | `transform.lot_financials_det` | `dbo.sp_load_fact_lot_financials` | `transform.sp_load_lot_financials_det` | standard |
| `dbo.fact_lot_financials_hist` | `transform.lot_financials_hist` | `dbo.sp_load_fact_lot_financials_hist` | `transform.sp_load_lot_financials_hist` | history |
| `dbo.fact_lot_sgm` | `transform.lot_sales_gross_margin_det` | `dbo.sp_load_fact_lot_sgm` | `transform.sp_load_lot_sales_gross_margin_det` | standard |
| `dbo.fact_lot_sgm_hist` | `transform.lot_sales_gross_margin_hist` | `dbo.sp_load_fact_lot_sgm_hist` | `transform.sp_load_lot_sales_gross_margin_hist` | history |
| `dbo.fact_sgm_assumptions` | `transform.sales_gross_margin_assumptions_det` | `dbo.sp_load_fact_sgm_assumptions` | `transform.sp_load_sales_gross_margin_assumptions_det` | standard |
| `dbo.fact_sgm_assumptions_hist` | `transform.sales_gross_margin_assumptions_hist` | `dbo.sp_load_fact_sgm_assumptions_hist` | `transform.sp_load_sales_gross_margin_assumptions_hist` | history |

### 1.3 Other objects in `dbo`

| Current | Disposition |
|---|---|
| `dim_job_task1`, `dim_job_task2` | DELETE (abandoned copies of `dim_job_task`; Phase 1 hygiene) |
| `UnitBudgets2025` | **Decided 2026-08-10 / producer 2026-08-19:** `transform.unit_budget_hist` (+ `analytics.unit_budget_hist`). Reload with `python3 automation/load_unit_budget_hist.py` (harvest + `transform.sp_load_unit_budget_hist`). `is_active=0` on stage_load_config so it stays off the 15-minute orchestrator. |
| `tbl_Milestones` | RENAME `transform.milestone` (applied in Foundation Development) |

### 1.4 `control` schema (kept)

`audit_orchestrator_control`, `audit_pipeline_control`, `audit_sp_control`, `audit_step_control`, `azure_vs_mirrored_db_audit_log`, `column_validation`, `row_validation` keep their names.

Renamed views: `vw_pipeline_performance_summary` -> `pipeline_performance_sum`, `vw_sp_performance_summary` -> `sp_performance_sum`.

New object: `control.stage_load_config`.

### 1.5 Schema-level findings (Confirmed 2026-08-04, new hygiene items)

| Finding | Action |
|---|---|
| Duplicate `CONTROL` schema (uppercase) exists alongside `control`, holds zero tables | Drop `CONTROL` in Phase 1 |
| `stage` schema exists in `EDW_Silver` with zero tables | Likely holds only views (OneLake listing shows tables only); confirm via SQL once az MFA is refreshed, then fold into the view rename pass |

---

## 2. Analytics layer: `EDW_Gold.dbo` → dbt `analytics.*` (all domains)

Target store in Foundation Development today: `lake_house_analytics.operations.*` (fed by dbt views in `warehouse_stage.analytics`). Domain tags: `shared` | `operations` | `finance` | `title`. See [`knowledge/analytics/gold-to-dbt-map.md`](../analytics/gold-to-dbt-map.md) for the full 37-view map. Do not recreate an `EDW_Gold` warehouse in FD.

| Current table | Target table | Notes |
|---|---|---|
| `dim_company` | `company` | |
| `dim_date` | `calendar` | |
| `dim_lot_active` | `lot_active` | RECOMMEND instead: fold into `lot` with an `is_active` flag and drop the extra table; keep `lot_active` only if the separate table earns its keep (D7 discussion) |
| `dim_operating_unit_active` | `operating_unit_active` | Same recommendation as `lot_active` |
| `dim_period_active` | `fiscal_period_active` | Same recommendation; follows the `fiscal_period` decision above |
| `dim_project_active` | `project_active` | Same recommendation |
| `dim_sale_active` | `sale_active` | Same recommendation |
| `rep_lot_events` | `lot_events_det` | `rep_` is a banned-style generic prefix; this is the feed behind lot event reporting |

The producer of these tables is still unidentified (Confirmed gap, P10). The rename lands with the new `pl_finance_analytics_refresh` producer in Phase 6, not by altering tables in place.

---

## 3. Known gaps in this map

1. **Views are not yet fully enumerated.** OneLake listing shows tables only; `sys.views` needs a SQL connection, and the Azure CLI token is expired with an MFA policy (Confirmed error AADSTS50078 on 2026-08-04). After the next `az login`, run the inventory query in `automation/sql/stage_load_config.sql` header comments and extend this map. The `vw_*` ban applies to whatever surfaces. First confirmed view (2026-08-05, from the live orchestrator definition): `control.vw_pipeline_performance_summary`, target name `control.pipeline_performance_sum`.
2. **Execution order in the seed script is inferred** from dependency common sense (references before transactions). Phase 3 must validate it against the ForEach order in `pp_orchestration_without_pp_audit` before cutover.
3. **Salesforce_WH is out of scope here**: it keeps `metadata` / `logging` schemas and its own config plane; its objects carry no banned prefixes (Confirmed in earlier deep dive).

---

## 4. Sign-off checklist (D7)

- [x] Confirm SGM expansion (sales gross margin) for 3 table names (approved 2026-08-06)
- [x] Confirm `dim_period` means fiscal period
- [x] Confirm `dim_major_minor` meaning (kept as `major_minor`; team can refine later)
- [x] Decide `tbl_Milestones` grain and final name (`transform.milestone`)
- [x] Decide `UnitBudgets2025` archive vs rename → `unit_budget_hist` (landed in FD 2026-08-10)
- [x] Decide `*_active` tables: kept separate in analytics layer for now
- [x] Enumerate and map views (37 gold views mapped to `analytics.*`)
- [x] Team sign-off recorded in `knowledge/decisions/README.md` (D7 decided 2026-08-06)
