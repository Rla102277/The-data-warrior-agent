# GBP-Enterprise pipeline gap register

**Updated:** 2026-08-12 (gaps closed in FD via `automation/fix_pipeline_gaps.py`)  
**Scope:** All 90 GBP-Enterprise DataPipeline items vs Foundation Development (**17 pipelines + 4 activators** after gap fix) and Foundation prod twin (promoted subset).  
**Evidence:** `orphan-scan.md` (2026-08-05), `catalog-gbp-enterprise.md`, live FD inventory and `automation/gap-fix-result.json` (2026-08-12).  
**Status:** Artifacts built in FD; **schedules remain OFF**. Promote wave 3 + smoke tests before go-live.

## Executive summary

GBP-Enterprise holds **90 pipelines**; **only 6 run in production**. Foundation now has **17 pipelines** (12 original + 5 gap closures) covering the live path without the 65-wrapper fleet.

**Gap fix (2026-08-12):** GAP-01 through GAP-06 closed in Foundation Development. GAP-07 (Key Vault role) still blocked on Randy.

| Metric | GBP-Enterprise | Foundation Development |
|---|---:|---:|
| Total pipelines | 90 | **17** |
| Live in prod (confirmed) | 6 | 0 (build-only; schedules OFF) |
| Wrapper / variant clutter | 65+ | 0 (metadata-driven) |
| Tracked open gaps | — | **1** (GAP-07 KV only) |

---

## Gap register

| ID | Gap | Enterprise source | Foundation status | Priority | Owner | Decision / next step |
|---|---|---|---|---|---|---|
| GAP-01 | Salesforce NSE WorkOrder CSV export to ADLS | `pp_load_view_to_csv` | **Closed (FD)** — `pipeline_salesforce_views_to_csv` (`4a6ca517-...`); wired as orchestrator step 3 | P1 | Data platform | Replace personal `ADLS kradhakrishnan` connection with workspace-owned ADLS before prod. Promote + smoke. |
| GAP-02 | Salesforce orchestrator Invoke chain | `pp_salesforce_orchestrator_prod` | **Closed (FD)** — 3-step Invoke chain wired; uses `gbp-data-pipeline` connection | P1 | Data platform | Smoke Invoke chain manually. Outbound still `IsActive=N`. Promote wave 3. |
| GAP-03 | Audit table cleanup schedule | `pp_audit_cleanup` | **Closed (FD)** — `pipeline_audit_cleanup` (`a6658e72-...`); schedule OFF | P2 | Data platform | Enable daily 00:00 Central after hydration go-ahead. |
| GAP-04 | History snapshot schedule | `pp_fact_hist_scheduled` + 3 child loaders | **Closed (FD)** — `pipeline_stage_history_load` (`7167c482-...`); direct hist proc calls, Tue/last-day criteria; schedule OFF | P2 | Finance + BI | Confirm hist tables still consumed; then enable schedule. |
| GAP-05 | Mirror vs source validation | `pp_compare_azure_vs_mirrored_db` | **Closed (FD)** — `pipeline_mirror_compare` (`c39694e4-...`); adapted from Enterprise; schedule OFF | P3 | Data platform + Ops | Verify Azure SQL mirror connections in FD; smoke before schedule. |
| GAP-06 | Failure alerting (Activators) | 5 Enterprise Reflexes | **Closed (FD + Foundation)** — 4 activators each workspace → `foundation_data_monitoring@greenbrickpartners.com`; `pipeline_health_obt` view live | P2 | Data platform | Confirm DL mailbox exists / receives mail; promote health into report when useful |
| GAP-07 | Zonda Key Vault access | `pp_load_zonda_to_fabric` | **Blocked** — `pipeline_zonda_load` exists; KV Secrets User not granted | P2 | Platform admin (Randy) | Randy runs role assignment in `knowledge/operations/identity.md`. |

### Gap status legend

| Status | Meaning |
|---|---|
| **Missing pipeline** | Business logic or proc exists elsewhere; no Foundation pipeline to run it |
| **Partial** | Artifact exists but not wired, bound, scheduled, or unblocked |
| **Covered** | Equivalent capability in Foundation (may differ in design) |
| **Not needed** | Intentionally excluded from rebuild |

---

## Live production path (confirmed)

Enterprise path today vs Foundation equivalent:

| Enterprise (live) | Runs (retention window) | Foundation equivalent | Register ID |
|---|---:|---|---|
| `pp_orchestration_without_pp_audit` | Continuous (15 min) | `pipeline_stage_orchestrator` | Covered |
| `pp_delete_blocked_logs` | Scheduled (2h IST) | Inline in orchestrator audit guard | Covered |
| `pp_salesforce_orchestrator_prod` | 429 | `pipeline_salesforce_orchestrator` | GAP-02 |
| `pp_fabric_salesforce_ingestion_prod` | 444 | `pipeline_salesforce_inbound` | GAP-02 |
| `pp_salesforce_fabric_ingestion_prod` | 331 | `pipeline_salesforce_outbound` | GAP-02 |
| `pp_load_view_to_csv` | 326 | `pipeline_salesforce_views_to_csv` | GAP-01 (closed) |
| EDW_Gold materialization | *(no pipeline in Enterprise)* | `dbt` + `pipeline_operations_analytics_refresh` | Covered (improvement) |
| `pp_load_zonda_to_fabric` | 0 in 30-day window | `pipeline_zonda_load` | GAP-07 |

---

## Intentionally not copied (not gaps)

| Category | Count | Rationale |
|---|---:|---|
| Dim/fact wrapper fleet (`_audit`, `_full`, `_no_audit`, base) | 65 | Production bypasses wrappers; live orchestrator calls `sp_load_*` procs directly |
| Dormant orchestrators | 4 | `pp_orchestration`, `_with_pp_audit`, `_full`, `_old`, `_test` — InvokePipeline pattern abandoned |
| Salesforce UAT/bkp/test clones | 5 | Prod-only rebuild; no parallel UAT workspace |
| `pp_temp_schema_discovery` | 1 | Scratch artifact |
| Individual entity one-off schedules | 2 | Absorbed into metadata-driven orchestrator |

Reference: `orphan-scan.md` sections A through C.

---

## Foundation-only additions (improvements over Enterprise)

| Pipeline | Purpose |
|---|---|
| `pipeline_operations_analytics_refresh` | Explicit analytics → lakehouse materialization (P10 gap Enterprise never closed) |
| `pipeline_stage_wave_runner` | Operator tool: run one wave on demand |
| `pipeline_sql_runner` | DDL and config deployment without UI |
| `pipeline_harvest_enterprise` | Read-only harvest from Enterprise for parity and budgets |
| `pipeline_salesforce_enterprise_copy` | Config harvest from Enterprise SF warehouse |
| `pipeline_salesforce_sql_runner` | SF warehouse DDL/config |
| `pipeline_salesforce_seed_smoke` | Smoke test without live SF pull |
| `pipeline_salesforce_views_to_csv` | NSE WorkOrder CSV export (replaces `pp_load_view_to_csv`) |
| `pipeline_audit_cleanup` | Audit table purge via `control.sp_audit_cleanup` |
| `pipeline_stage_history_load` | History snapshots (replaces `pp_fact_hist_scheduled` chain) |
| `pipeline_mirror_compare` | Mirror vs Azure SQL validation |
| `notebook_operations_backup_cleanup` | Wired into analytics refresh (F5 fix) |

## Foundation Development activators (GAP-06)

| Activator | Watches | Alert destination |
|---|---|---|
| `activator_stage_orchestrator_failure` | `pipeline_stage_orchestrator` | `foundation_data_monitoring@greenbrickpartners.com` |
| `activator_salesforce_orchestrator_failure` | `pipeline_salesforce_orchestrator` | same |
| `activator_analytics_refresh_failure` | `pipeline_operations_analytics_refresh` | same |
| `activator_zonda_load_failure` | `pipeline_zonda_load` | same |

Deploy script: [`automation/fix_pipeline_gaps.py`](../../automation/fix_pipeline_gaps.py). Artifact IDs: [`automation/gap-fix-result.json`](../../automation/gap-fix-result.json).

---

## Recommended build sequence (before schedules ON)

1. **GAP-02** — Wire Salesforce orchestrator + connection binds (blocks GAP-01 integration).
2. **GAP-01** — If business confirms NSE export need, build views-to-CSV pipeline.
3. **GAP-03** — Audit cleanup before orchestrator hydration.
4. **GAP-04** — History schedule only if Finance/Ops confirm hist tables are consumed.
5. **GAP-06** — Activators before enabling prod schedules.
6. **GAP-07** — KV role for Zonda seasonal loads.
7. **GAP-05** — Mirror compare only if Ops wants drift detection renewed.

---

## Related documents

| Document | Role |
|---|---|
| `orphan-scan.md` | Definitive over-engineering analysis (6 live, 77 deletable) |
| `catalog-gbp-enterprise.md` | Full prod catalog with schedules and run health |
| `schedule-truth-table.md` | Active vs expired vs Reflex alerts |
| `salesforce-ingestion-prod.md` | SF orchestrator 3-step chain detail |
| `utilities.md` | Audit, compare, Zonda, blocked-logs, view-to-csv, hist |
| `knowledge/operations/analytics-setup.md` | FD pipeline IDs and folder layout |
| `knowledge/operations/deployment-pipeline.md` | Promote and rebind runbook |

---

## Change log

| Date | Change |
|---|---|
| 2026-08-12 | Initial register from CDO pipeline gap analysis |
| 2026-08-12 | GAP-01..06 closed in FD via `automation/fix_pipeline_gaps.py`; GAP-07 KV still blocked |
