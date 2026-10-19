# Salesforce in Foundation Development (D13)

**Date:** 2026-08-12  
**Approach:** Additive rebuild in Foundation Development. Not a 1:1 clone of GBP-Enterprise Salesforce siblings (no UAT/bkp/test copies).  
**Workspace folder:** `utilities/salesforce` (FD and Foundation). Not under `analytics`.  
**D12:** Prod GBP-Enterprise Salesforce pipelines and `Salesforce_WH` are untouched. Outbound writes to Salesforce from FD are **disabled** until an explicit UAT connection approval.

## Identity map (FD)

| Role | FD name | Enterprise source |
|---|---|---|
| Warehouse | `warehouse_salesforce` (`097e3522-...`) | `Salesforce_WH` |
| Lakehouse (empty shell) | `lake_house_salesforce` | `Salesforce.Lakehouse` (not shortcuted yet) |
| Inbound | `pipeline_salesforce_inbound` | `pp_salesforce_fabric_ingestion_prod` |
| Outbound | `pipeline_salesforce_outbound` | `pp_fabric_salesforce_ingestion_prod` |
| Orchestrator | `pipeline_salesforce_orchestrator` | `pp_salesforce_orchestrator_prod` (3-step Invoke wired 2026-08-12) |
| Views to CSV | `pipeline_salesforce_views_to_csv` | `pp_load_view_to_csv` |
| SQL utility | `pipeline_salesforce_sql_runner` | (new) |
| Config harvest | `pipeline_salesforce_enterprise_copy` | reads Enterprise `Salesforce_WH` → scratch |
| Seed smoke | `pipeline_salesforce_seed_smoke` | copies `dbo.Community__c` Enterprise → FD |

## Config plane

- `metadata.Ingestion_Config` — 17 rows copied from Enterprise; Pipeline_Name remapped to D13 names.
- **Inbound** rows: `IsActive=Y`.
- **Outbound** rows: `IsActive=N` (blocks Fabric → Salesforce_Prod from FD).
- `logging.Pipeline_Table_Load_Log` — empty shell for future runs.

## Safety

1. Do **not** schedule `pipeline_salesforce_orchestrator` or outbound until Salesforce **UAT** connection is bound and outbound rows are flipped to `Y` with written approval.
2. Inbound may be run after binding the Salesforce connection in the FD workspace (reads Salesforce, writes only to `warehouse_salesforce`).
3. Enterprise prod sync stays on GBP-Enterprise schedules (10/13/16 Central).

## Smoke (2026-08-10)

| Check | Result |
|---|---|
| Create `warehouse_salesforce` / `lake_house_salesforce` | Succeeded |
| Seed `metadata.Ingestion_Config` (17 rows; outbound `IsActive=N`) | Succeeded |
| Import inbound / outbound / utilities | Succeeded |
| WH→WH copy of `Community__c` | Failed (Fabric DataWarehouse Copy does not support WH source→WH sink) |
| Enterprise SF WH query → scratch (`COUNT(*)` on `Community__c`) | Succeeded (**392** rows) via `pipeline_salesforce_enterprise_copy` |

Inbound live Salesforce pull requires binding the Salesforce connection on the FD pipeline in the UI (not automated here).

## Gap fix (2026-08-12)

| Item | FD ID | Status |
|---|---|---|
| `pipeline_salesforce_views_to_csv` | `4a6ca517-8687-4d05-a092-716eb9e14004` | Created; ADLS still uses shareable `ADLS kradhakrishnan` connection |
| `pipeline_salesforce_orchestrator` Invoke chain | `289f00c3-7d24-4d06-8442-0186216beecc` | Wired: outbound → inbound → views_to_csv via `gbp-data-pipeline` |

Deploy: `python3 automation/fix_pipeline_gaps.py`

## Connection bind status (2026-08-12)

| Pipeline | Connection | Notes |
|---|---|---|
| `pipeline_salesforce_inbound` | **Salesforce_UAT** (`37551f20-…`) | Rebound from Prod 2026-08-12 for safe smoke |
| `pipeline_salesforce_outbound` | **Salesforce_UAT** (`37551f20-…`) | Same; config rows still `IsActive=N` |
| `pipeline_salesforce_views_to_csv` | **Foundation ADLS gbpintegrationfiles** (`ef7726de-…`, WorkspaceIdentity) | Replaces personal `ADLS kradhakrishnan` |
| `pipeline_salesforce_orchestrator` | `gbp-data-pipeline` Invoke | Wired; do not schedule |

ADLS WI connection path: `https://gbpintegrationfiles.dfs.core.windows.net/integration-files`.
WI group needs **Storage Blob Data Contributor** on `gbpintegrationfiles` for runtime writes (grant if smoke fails on auth).

## Remaining manual steps

1. Smoke the orchestrator Invoke chain manually (schedules OFF; outbound inactive; UAT only).
2. Confirm WI has Storage Blob Data Contributor on `gbpintegrationfiles` if CSV export auth fails.
3. Promote wave 3 to Foundation twin when ready.
4. Re-enable outbound only against UAT, never against `Salesforce_Prod` from FD without an explicit cutover instruction.
