# EDW deep dive (dim / fact / orchestration)

**Documented:** 2026-07-15  
**Workspace:** GBP-Enterprise  
**Primary store:** `EDW_Silver.Warehouse` (id `afcce380-11a2-4e14-8bd4-89f731a30848`)  
**Evidence:** pipeline definition exports + SQL against `EDW_Silver` / `EDW_Gold`

---

## What the EDW load pattern is

Almost every `pp_load_stg_to_dim_*` / `pp_load_stg_to_fact_*` pipeline is a thin Fabric wrapper around a **warehouse stored procedure** in `EDW_Silver.dbo`.

Confirmed proc map (base pipelines):

| Pipeline | Stored procedure |
|---|---|
| `pp_load_stg_to_dim_company` | `dbo.sp_load_dim_company` |
| `pp_load_stg_to_dim_division` | `dbo.sp_load_dim_division` |
| `pp_load_stg_to_dim_job` | `dbo.sp_load_dim_job` |
| `pp_load_stg_to_dim_job_task` | `dbo.sp_load_dim_job_task` |
| `pp_load_stg_to_dim_lot` | `dbo.sp_load_dim_lot` |
| `pp_load_stg_to_dim_major_minor` | `dbo.sp_load_dim_major_minor` |
| `pp_load_stg_to_dim_operating_unit` | `dbo.sp_load_dim_operating_unit` |
| `pp_load_stg_to_dim_period` | `dbo.sp_load_dim_period` |
| `pp_load_stg_to_dim_project` | `dbo.sp_load_dim_project` |
| `pp_load_stg_to_dim_sale` | `dbo.sp_load_dim_sale` |
| `pp_load_stg_to_dim_sale_transfer` | `dbo.sp_load_dim_sale_transfer` |
| `pp_load_stg_to_dim_sgm_map` | `dbo.sp_load_dim_sgm_map` |
| `pp_load_stg_to_fact_general_ledger` | `dbo.sp_load_fact_general_ledger` |
| `pp_load_stg_to_fact_lot_financials` | `dbo.sp_load_fact_lot_financials` |
| `pp_load_stg_to_fact_lot_sgm` | `dbo.sp_load_fact_lot_sgm` |
| `pp_load_stg_to_fact_sgm_assumptions` | `dbo.sp_load_fact_sgm_assumptions` |

History procs (Confirmed in warehouse + pipelines):

- `dbo.sp_load_fact_lot_financials_hist`
- `dbo.sp_load_fact_lot_sgm_hist`
- `dbo.sp_load_fact_sgm_assumptions_hist`

Also present in warehouse but **no matching base pipeline** observed: `dbo.sp_load_dim_date` (date dimension exists as `dbo.dim_date`).

Target tables in `EDW_Silver.dbo` (Confirmed): all listed dims/facts above plus `*_hist` fact tables, `dim_job_task1/2`, `tbl_Milestones`, `UnitBudgets2025`.

---

## Variant semantics (Confirmed from definitions)

Same stored procedure is reused across variants. Behavior changes via **pipeline shape** and **parameters**, not via different proc names.

| Variant | Typical shape | `LoadType` behavior | Audit logging to `control.*` |
|---|---|---|---|
| **base** (no suffix) | Lookup watermark → If empty then FULL else INCREMENTAL → call SP with `MaxDateTime` | Dynamic: empty table ⇒ `FULL`, else `INCREMENTAL` | Often includes start/end audit Scripts |
| **`_audit`** | Audit Scripts + Lookup audit key → call SP | Uses `v_load_type` + `AuditId` + `OrchestratorAuditId` | Yes (`control.audit_pipeline_control`) |
| **`_full`** | Same as audit-style wrapper | Default variable `v_load_type = 'FULL'` (Confirmed on company_full) | Yes |
| **`_no_audit`** | Minimal: often just SP call | Passes `LoadType` / audit ids when present | No start/end audit Scripts |
| **`_hist`** (facts) | Similar to base watermark pattern | Calls `*_hist` proc | Varies |

### Base watermark logic (example: `pp_load_stg_to_dim_company`)

1. `lkp_last_modified_date` reads max watermark from the target side  
2. `check_load_type` IfCondition:  
   - if max_date == `'Table is empty'` → set `v_load_type = FULL`  
   - else → set `v_load_type = INCREMENTAL` and `v_max_last_modified_date`  
3. `SqlServerStoredProcedure` `sp_load_dim_company` with params:
   - `JobRunId`, `LoadType`, `MaxDateTime`, `AuditId`

### Audit control tables (Confirmed in `EDW_Silver`)

| Table | Role |
|---|---|
| `control.audit_pipeline_control` | Per child pipeline run (start/end/status/type_of_run) |
| `control.audit_orchestrator_control` | Orchestrator run envelope |
| `control.audit_sp_control` | Stored procedure level |
| `control.audit_step_control` | Step level |
| `control.azure_vs_mirrored_db_audit_log` | Mirror compare utility |
| `control.column_validation` / `control.row_validation` | Validation |

Recent `audit_pipeline_control` rows show `type_of_run = MANUAL_HISTORY_LOAD` for June 2026 full loads.

---

## Orchestrators: how they differ

### `pp_orchestration_without_pp_audit` (operational workhorse)

- **Schedule:** active Cron every **15 minutes** Central (through 2026-12-31)  
- **Implementation:** does **not** InvokePipeline children; it **inlines** the `sp_load_*` calls in one pipeline  
- **Audit evidence:** `control.audit_orchestrator_control` shows recent SUCCESS rows for this name (including 2026-07-05)  
- Reflex `act_pp_orchestration_without_pp_audit` emails `randerson@greenbrickpartners.com` on ItemJobFailed

### `pp_orchestration_with_pp_audit`

- **Schedule:** present but **disabled** (30 min Cron)  
- **Implementation:** InvokePipeline → `*_audit` child pipelines (16 invokes)  
- Tracks per-child failure variables (`v_dim_company_failed_activity`, etc.)  
- Reflex failure alert to same operator email

### `pp_orchestration_full`

- InvokePipeline → `*_full` (and some `*_audit`) children  
- Used for history / full refresh style runs (aligns with MANUAL_HISTORY_LOAD audit rows)

### `pp_orchestration` / `pp_orchestrator_test`

- InvokePipeline → base (non-suffix) children  
- Schedules disabled / expired test windows

### `pp_fact_hist_scheduled`

- Invokes the three `pp_load_fact_*_to_fact_*_hist` pipelines  
- Pipeline schedule **expired** (ended 2025-12-31)

---

## Gold layer (Confirmed names)

`EDW_Gold.Warehouse` tables observed:

- `dbo.dim_company`, `dbo.dim_date`
- `dbo.dim_lot_active`, `dbo.dim_operating_unit_active`, `dbo.dim_period_active`, `dbo.dim_project_active`, `dbo.dim_sale_active`
- `dbo.rep_lot_events`

Operations workspaces also host `EDW_Gold.Lakehouse` (domain gold presentation; Confirmed item exists). Exact silver→gold transform ownership is **Inferred** as downstream of `EDW_Silver` dims/facts (no dedicated `pp_load_stg_to_gold_*` pipelines found).

---

## Practical guidance for changes

1. Prefer changing **`dbo.sp_load_*`** logic in `EDW_Silver` for business rules; pipelines mostly pass `LoadType` / watermarks / audit ids.  
2. For incremental EDW refresh in prod today, assume **`pp_orchestration_without_pp_audit`** is the live cadence (15 min), not the audit/full orchestrators.  
3. Use `*_full` / `pp_orchestration_full` for rebuilds; expect `MANUAL_HISTORY_LOAD` style audit rows.  
4. Keep variant naming when cloning entities: base / audit / full / no_audit (+ hist for facts).

Related docs: `edw-orchestration.md`, `catalog-gbp-enterprise.md`, lineage map in `knowledge/lineage/`.
