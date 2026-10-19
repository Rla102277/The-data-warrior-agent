# GBP-Enterprise orphan scan

**Documented:** 2026-08-05  
**Scope:** all 171 items in GBP-Enterprise.Workspace (live), full reference graph over all 90 pipeline definitions plus 5 Reflex definitions, schedules API per pipeline, and job run history per pipeline.  
**Data:** `data/orphan-scan-2026-08-05/` (graph.json, runs.json, and the 14 definitions the snapshot export missed)

## Method and caveats

Confirmed evidence: pipeline and Reflex definitions were scanned for artifact ID references (invoked pipelines, dataflows, notebooks, warehouses), joined with per-item schedules from the jobs API and recent run instances.

Caveats:
1. Run history comes from the Fabric jobs API retention window (roughly the last 30 days, capped at 100 rows per item). "Zero runs" means no runs in that window, not never.
2. Stored procedures reference stores by SQL name, not artifact ID, so warehouse and lakehouse usage by SQL is not captured here. Semantic model bindings are also not captured. Non-pipeline items are therefore flagged only as "not referenced by any pipeline or Reflex definition."
3. `pp_load_zonda_to_fabric` may be seasonal (Zonda deliveries are periodic); zero runs in a 30 day window is not proof of abandonment.

## The live set (Confirmed, 6 of 90 pipelines)

| Pipeline | How it runs | Last run |
|---|---|---|
| `pp_orchestration_without_pp_audit` | Enabled cron, 15 min, Central, ends 2026-12-31 | 2026-08-05, running at scan time |
| `pp_delete_blocked_logs` | Enabled cron (India Standard Time) | 2026-08-05 |
| `pp_salesforce_orchestrator_prod` | Scheduled runs confirmed daily; schedules API returns HTTP 400 for this item (broken schedule entity, see findings) | 2026-08-05 |
| `pp_fabric_salesforce_ingestion_prod` | Invoked by Salesforce orchestrator | 2026-08-05 |
| `pp_salesforce_fabric_ingestion_prod` | Invoked by Salesforce orchestrator | 2026-08-05 |
| `pp_load_view_to_csv` | Invoked by Salesforce orchestrator | 2026-08-05 |

**Key structural finding (Confirmed):** the live 15 minute orchestrator contains only `SqlServerStoredProcedure` activities calling `sp_call_dim_*` / `sp_call_fact_*` procs directly. It invokes zero child pipelines. The entire wrapper pipeline fleet is bypassed by the production path.

## Orphan pipelines: 77 of 90 are deletable

All of the following have zero runs in the retention window and are reachable only from dormant roots (or from nothing at all).

### A. Test, backup, and temp clutter (9)

No inbound references, no active schedule, zero runs:

`pp_fabric_salesforce_ingestion_UAT`, `pp_fabric_salesforce_ingestion_bkp1`, `pp_salesforce_fabric_ingestion` (superseded by `_prod`; its only reference is the mis-bound failure Reflex `act_job_event_failure_alerts`), `pp_salesforce_fabric_ingestion_UAT`, `pp_salesforce_fabric_ingestion_bkp1`, `pp_salesforce_fabric_ingestion_test`, `pp_temp_schema_discovery`, `pp_orchestration_without_pp_audit_old`, `pp_orchestrator_test`

### B. Dormant orchestrators (3)

Zero runs, schedules disabled or expired:

| Orchestrator | Schedule state |
|---|---|
| `pp_orchestration` | Disabled, expired 2025-12-31 |
| `pp_orchestration_full` | No schedule |
| `pp_orchestration_with_pp_audit` | Disabled (runs to 2026-12-17 if ever re-enabled) |

### C. The wrapper fleet (65)

Every `pp_load_stg_to_dim_*` and `pp_load_stg_to_fact_*` wrapper (base, `_audit`, `_full`, `_no_audit`) plus the three `pp_load_fact_*_to_*_hist` loaders. Zero runs across all 65. Reference status:

| Variant group | Count | Referenced by |
|---|---|---|
| Base wrappers | 16 | Only `pp_orchestration` (dormant) and `pp_orchestrator_test` (dormant); 2 of them (`fact_lot_sgm`, `fact_sgm_assumptions`) by nothing at all |
| `_audit` wrappers | 16 | Only `pp_orchestration_with_pp_audit` (dormant) |
| `_full` wrappers | 14 | Only `pp_orchestration_full` (dormant) |
| `_no_audit` wrappers | 16 | Nothing at all |
| `pp_load_fact_*_to_*_hist` | 3 | Only `pp_fact_hist_scheduled` (expired, see D) |

The `sp_load_*` stored procedures these wrappers call remain in use via the live orchestrator's `sp_call_*` procs; deleting the wrappers deletes no business logic.

### D. Expired history chain (4): operational gap, decide before deleting

`pp_fact_hist_scheduled` schedule is enabled but **expired 2025-12-31**. It and its three children have zero runs. Consequence (Inferred, verify row counts): `fact_lot_financials_hist`, `fact_lot_sgm_hist`, and `fact_sgm_assumptions_hist` have received no snapshots for over 7 months. If history matters, this is a data gap to close, not just clutter to delete. The rearchitecture replaces this chain with `pl_stage_history_load`.

### E. Utility orphans needing a decision (3)

| Pipeline | State | Recommendation |
|---|---|---|
| `pp_audit_cleanup` | Schedule enabled but expired 2025-12-31; zero runs | Renew now. The live orchestrator writes audit rows every 15 minutes and nothing has pruned them since December (Inferred growth; verify `control` table row counts) |
| `pp_compare_azure_vs_mirrored_db` | Expired 2025-12-31 (Eastern tz); one manual run 2026-07-23 which **Failed** | Someone tried to use it three weeks ago and it broke. Fix and renew, or retire deliberately |
| `pp_load_zonda_to_fabric` | No schedule, zero runs in window; has its own failure Reflex | Keep; likely seasonal on-demand |

## Non-pipeline items not referenced by any pipeline or Reflex

Subject to caveat 2 (SQL and semantic model usage not visible to this scan):

| Type | Items | Assessment |
|---|---|---|
| Dataflow | `DataverseConnector`, `Salesforce_Test` | `Salesforce_Test` is a test artifact, delete candidate; `DataverseConnector` may refresh on its own schedule, verify before touching |
| Lakehouse | `StagingLakehouseForDataflows_*` (4), `StagingLakehouseForDataflows_Default`, `DataflowsStagingLakehouse` | Dataflow scaffolding, abandoned; archive candidates (already flagged P3) |
| Warehouse | `StagingWarehouseForDataflows_*` (4), `DataflowsStagingWarehouse`, `DataflowsStagingWarehouse1` | Same scaffolding pattern |
| Warehouse | `WebsiteData` | Not referenced by any pipeline; identify its producer and consumers before Phase 5 |
| SemanticModel | `Salesfor` (truncated name), `xx260527DataflowsStagingWarehouse` | Junk names, delete candidates after checking report bindings |
| Notebook | 12 of 16 (`APDetails`, `Checks`, `GLBalance`, `JobCostDetails`, `JobScrub`, `LotDetails`, `LotMultiBudget`, `LotOptions`, `Notebook 4`, `Notebook_1`, `PODetails`, `TitleBooking`) | Ad hoc analysis notebooks, not orchestrated; not orphans in the delete sense, but they belong in a dev workspace, not prod |
| Lakehouse | `BuildPro`, `HBLive`, `SPLive`, `Salesforce`, `Zonda`, `dataverse_*`, `gbp_lakehouse` | Referenced by SQL and Copy activities via connections, not artifact IDs; NOT orphans, listed only for completeness |
| Warehouse | `EDW_Gold` | No pipeline references it. Strengthens the P10 finding: its producer is not a pipeline; most likely cross-database writes from `EDW_Silver` procs (Inferred, confirm via proc text once az MFA is refreshed) |

## Other findings from the scan

1. **`pp_salesforce_orchestrator_prod` schedule entity is broken (Confirmed):** runs arrive marked `Scheduled` daily, but the schedules API returns HTTP 400 for every job type on this item. This matches the July observation that its `.schedules` file vanished from exports. Recreate the schedule cleanly during Phase 1.
2. **The 2026-08-04 snapshot export silently missed 14 pipelines**, including every live Salesforce pipeline and the live orchestrator. Their definitions were fetched via API and stored under `data/orphan-scan-2026-08-05/missing-export-defs/`. Investigate `export-fabric-live.sh` (likely failing on items whose connections require interactive auth) before trusting nightly snapshots as DR.
3. **Correction (2026-08-05, after full definition parse):** the live orchestrator's activities are *named* `sp_call_*`, but each one calls `[dbo].[sp_load_*]` directly. No `sp_call_*` procs exist; the July proc inventory and the rename map are already complete on this point. Full detail in `knowledge/lineage/orchestrator-e2e.md`.
4. `pp_load_stg_to_dim_project` still carries an enabled schedule that expired 2025-05-23; `pp_delete_blocked_logs` runs on India Standard Time (existing P7 finding, reconfirmed).

## Recommended actions (feeds Phase 1 hygiene)

1. Delete groups A and B and the `_no_audit` wrappers (28 pipelines with zero inbound references) immediately; definitions are preserved in snapshot plus `missing-export-defs`.
2. Decide the history gap (D), then delete the chain once `pl_stage_history_load` or a renewed schedule covers it.
3. Renew `pp_audit_cleanup` today; verify audit table growth since December.
4. Delete remaining wrapper fleet (C) after the team confirms nobody runs them manually outside the 30 day window (for example quarter-end full loads via `pp_orchestration_full`).
5. Recreate the Salesforce orchestrator schedule; fix or retire `pp_compare_azure_vs_mirrored_db`.
6. Fix the export script gap so snapshots are complete.
