# Foundation deployment pipeline

**Created:** 2026-08-10  
**Status:** Wired. **First full promote completed 2026-08-10** (Foundation Development → Foundation). Legacy Enterprise / Finance / Operations were not modified.

## Pipeline

| Field | Value |
|---|---|
| Display name | `Foundation` |
| Pipeline ID | `369a8272-7267-4161-a634-9bd34ac8e99e` |
| Development stage | `d0ee4296-1e2a-4bb8-8a1f-3917d0e97ff7` → workspace **Foundation Development** (`40502864-6ece-49b5-807f-6f7c11d1b3e1`) |
| Production stage | `e611a3cc-8823-44c8-8466-5a556e43bf24` → workspace **Foundation** (`7c1850c1-821f-4fc7-a823-c186516023c6`) |

Open in Fabric UI: Deployment pipelines → **Foundation**.

## Deployed inventory (parity)

**Third promote 2026-08-18** brought FD and Foundation back to name
parity (52 deployable stage items each; 60 workspace items including
SQL endpoints). Second promote (2026-08-12) was 39/39 non-SQLEndpoint
items. First promote (2026-08-10) was 26/26.

| Type | Count (after 2026-08-18) |
|---|---:|
| DataPipeline | 16 |
| Lakehouse | 8 |
| Warehouse | 2 |
| SemanticModel | 8 |
| Report | 7 |
| Notebook | 5 |
| VariableLibrary | 1 |
| DataBuildToolJob | 1 |

SQL endpoints follow lakehouses/warehouses and are not listed separately as deployable stage items.

### Third promote notes (2026-08-18)

User approved Foundation twin match for 18 Aug 2026 22:13 / 22:45
Central one-shots. Promote ran in the afternoon so deploy and hydrate
do not overlap. Warehouses/lakehouses were not redeployed.

Nine FD-only items, all Succeeded (deployment `9cc6b47e-b3f1-4839-915e-7da4e54d8dba`):

| Item | Type | Foundation ID | Folder |
|---|---|---|---|
| `pipeline_audit_cleanup` | DataPipeline | `1b5a968c-59d0-4625-b8d5-95d1ea2deec3` | utilities |
| `pipeline_mirror_compare` | DataPipeline | `aa0e1834-c49d-44c7-be16-14f24cc4128c` | utilities |
| `pipeline_salesforce_views_to_csv` | DataPipeline | `a5eee55b-df25-4c17-b28a-d36e631d419a` | utilities/salesforce |
| `pipeline_stage_history_load` | DataPipeline | `85133ab6-b193-428c-affb-efa4b4aba210` | utilities |
| `report_operations_lot_events` | Report | `6148eb2d-86d2-4f71-a5a6-a40c89924f66` | analytics/operations |
| `report_operations_sales` | Report | `6a015cad-e45f-47e7-afbb-aec408f02c59` | analytics/operations |
| `semantic_model_operations_lot_events` | SemanticModel | `27b5ef71-f909-462e-8440-73e7c16d7a50` | analytics/operations |
| `semantic_model_operations_sales` | SemanticModel | `9c9007cb-b406-466a-88fe-07240a815714` | analytics/operations |
| `semantic_model_title_booking` | SemanticModel | `369cea77-66c2-486b-9df6-3a2019812a04` | analytics/Title |

First deploy POST returned `TargetSubfolderNameConflict` on unpaired
`analytics/Title` and `utilities/salesforce` folders (same names exist
in both workspaces but were not pipeline-paired). Non-destructive
workaround: temporarily moved the two source items into paired parent
folders, deployed, restored FD folders, placed Foundation copies in
the analog folders above. History / Salesforce / audit / mirror
pipelines were **not** enabled or run.

Post-deploy:

- `python3 automation/rebind_endpoints.py "Foundation" --apply` rebound
  the 4 new pipelines FD host -> Foundation host
  (`...-yfibq7a7qldu7kbdygdfcybdyy...`). Existing pipelines already
  matched. GBP-Enterprise hosts left as `extern`.
- Promoted SMs host-rewritten to Foundation SQL host and bound to
  **Foundation Lake** (`73fac61d-894a-4dd8-909a-99d369f2b026`). Existing
  Finance / CustSat SMs already on Foundation host; table names patched
  to the unsuffixed 29-entity contract. CustSat also bound to Foundation
  dataverse (`8e7c07b9-…`).
- Reseeded Foundation `control.analytics_refresh_config` to **29** rows
  (was stale 39). `pipeline_health_obt` stays warehouse-only.
- One-shot Daily schedules (Central, end 2026-08-18 23:59): orchestrator
  22:13 (`0fac8959-…`), analytics refresh 22:45 (`6da6ddeb-…`),
  `p_domain` default `all`. 15-min cron left **disabled** on FD and
  Foundation. Disable-after-run is required in the morning.
- SOX/git still blocked separately. Do not enable recurring after this
  window.

### Second promote notes (2026-08-12)

Wave 2A (12): `lake_house_zonda`, 4 Zonda notebooks, `notebook_operations_backup_cleanup`,
Finance Unit + Weekly Sales/Unit SMs/reports.  
Wave 2B (2): `pipeline_zonda_load`, `pipeline_operations_analytics_refresh` (cleanup
notebook remap). Both waves Succeeded. Schedules remain **disabled**.

Post-deploy:

- Rebound `pipeline_operations_analytics_refresh` SQL host FD → Foundation (`--apply`).
- Confirmed cleanup + Zonda notebook activity IDs remapped to Foundation workspace.
- Finance SMs still embedded the FD SQL host after promote; rewrote all four
  Finance semantic model definitions to Foundation host
  (`...-yfibq7a7qldu7kbdygdfcybdyy...`) and bound them to new ShareableCloud
  **Foundation Lake** (`73fac61d-894a-4dd8-909a-99d369f2b026`, WorkspaceIdentity).
- No SM refresh / data load run.

## First promote notes (2026-08-10)

Clarification: “do not change production” means **legacy** prod (GBP-Enterprise, Finance, Operations). The **Foundation** workspace is the prod twin and may receive full pushes.

Wave history:

1. Full deploy failed on `warehouse_stage` (`CopyOverwriteResult.GenericError`) while importing analytics views that referenced empty HBLive/SPLive objects; left an unpaired orphan warehouse shell.
2. Wave A: remaining lakehouses, semantic models, reports, non-warehouse-dependent pipelines (Succeeded).
3. Wave B1: `warehouse_salesforce` (Succeeded).
4. Wave B2: Salesforce pipelines (Succeeded).
5. Deleted unpaired orphan `warehouse_stage` in Foundation; Wave B3 hit name conflict while soft-delete settled.
6. Wave B4: `warehouse_stage` (Succeeded after orphan gone).
7. Wave B5: stage / sql / analytics-refresh pipelines (Succeeded).

**Warehouse caveat:** schema/data are not a full Dev clone of loaded tables. Re-run stage orchestrator / SQL runners / analytics refresh in Foundation after connections and lakehouse shortcuts are bound. If warehouse deploy fails again with view import errors, remove any unpaired target shell first, ensure dependent lakehouses exist, then retry warehouse alone before dependent pipelines.

**Do not enable** Salesforce outbound against Salesforce_Prod. Keep outbound `IsActive=N` until UAT is approved.

## Post-deploy checklist

1. Rebind connections in **Foundation**: warehouse SQL hosts, Salesforce (inbound only), Dataverse, lakehouse shortcuts to Enterprise sources.
2. Run `pipeline_stage_orchestrator` / `pipeline_operations_analytics_refresh` only after sources are wired.
3. Refresh semantic models; open CustSat + Finance reports in Foundation.
4. Leave Enterprise / Finance / Operations legacy prod untouched (D12) unless separately instructed.

## Post-deploy progress (2026-08-11)

Done (no data runs):

- Lakehouse shortcuts already present in Foundation (parity with Dev: HBLive 27, BuildPro 6, SPLive 22, dataverse_gbpdev 9).
- Seeded empty control configs in Foundation `warehouse_stage` (`stage_load_config` 20, `analytics_refresh_config` 39) and SF `metadata.Ingestion_Config` (17 rows; **0 outbound active**).
- Rewrote Foundation pipeline warehouse **endpoints** from Dev SQL host (`...-mqufaqgon22utad7n56bdunt4e...`) to Foundation host (`...-yfibq7a7qldu7kbdygdfcybdyy...`). Artifact IDs were already Foundation-local after deploy; mismatched host caused `SqlFailedToConnect` / database not found.
- Foundation stage + analytics **schedules remain disabled**. Do not enable until an explicit off-hours load plan.
- Capacity: shared `gbpwus3fabric01` hit ~90% when Foundation full load overlapped FD schedules. FD schedules re-enabled; Foundation stays quiet.

Deferred (capacity-safe later):

- Any Foundation stage / analytics / harvest / SM refresh jobs
- Semantic model cloud connection bind in UI (CustSat + Finance) then refresh
- Salesforce inbound smoke (outbound stays `IsActive=N`)

## Deploy runbook (Foundation Development -> Foundation)

Lessons from the 2026-08-10 first promote, written as the repeatable procedure.

### Pre-deploy

1. Confirm target: deployment pipeline **Foundation** (`369a8272-7267-4161-a634-9bd34ac8e99e`), source stage Development, target stage Production. Legacy workspaces are never targets.
2. Validate source hosts: `python3 automation/rebind_endpoints.py "Foundation Development"` must exit 0.
3. Confirm all schedules in the target are disabled (they stay disabled through the deploy; enabling is a separate, deliberate decision).
4. Snapshot: run `automation/export-fabric-live.sh` (or confirm a snapshot from today exists under `snapshots/`).

### Deploy waves

Deploy in this order; do not deploy everything at once (warehouse view import fails if dependent lakehouses/objects are missing in the target):

1. **Wave A** - Lakehouses, semantic models, reports, variable library, dbt job, and pipelines with no warehouse dependency.
2. **Wave B1** - `warehouse_salesforce`.
3. **Wave B2** - Salesforce pipelines.
4. **Wave B3** - `warehouse_stage` (see recovery below if it fails).
5. **Wave B4** - stage / sql-runner / analytics-refresh pipelines.

Deploy API: `POST /v1/deploymentPipelines/{id}/deploy` with `sourceStageId`, `targetStageId`, and an `items` array to scope each wave. The `note` field must be a plain string.

### Warehouse failure recovery

If a warehouse deploy fails (`CopyOverwriteResult.GenericError` on view import, or leaves an unpaired shell):

1. Delete the unpaired orphan warehouse in the **target** workspace only.
2. Wait for the soft-delete to settle (a few minutes; retrying too fast gives `TargetArtifactNameConflict`).
3. Ensure the lakehouses the views reference exist in the target with shortcuts bound.
4. Redeploy the warehouse alone, then its dependent pipelines.

### Post-deploy (every promote)

1. **Host validation/rebind:** `python3 automation/rebind_endpoints.py "Foundation"`; if it reports WRONG hosts, rerun with `--apply`. Deployment remaps artifact IDs but not SQL endpoint hosts. References to the GBP-Enterprise host in `pipeline_harvest_enterprise` / `pipeline_salesforce_enterprise_copy` / `pipeline_salesforce_seed_smoke` are intentional (`extern` in the report) - never rewrite those.
2. **Reseed control configs** in target `warehouse_stage` if schema was recreated: `stage_load_config` (20 rows), `analytics_refresh_config` (29 rows; current FD contract, no `*_active` twins), SF `metadata.Ingestion_Config` (17 rows, all outbound `IsActive=N`). Seeds: `automation/sql/*.sql` via `pipeline_sql_runner`.
3. **Cross-item references:** verify pipeline activities that call other items by ID were remapped (e.g. `cleanup_backup_tables` notebook activity in `pipeline_operations_analytics_refresh` must point at the target workspace's `notebook_operations_backup_cleanup`).
4. **Schedules:** confirm everything is still disabled in the target (`Pipeline` job schedules, semantic model refresh, dbt job). Foundation runs nothing until hydration is explicitly approved and off-hours.
5. **Salesforce outbound stays off** (`IsActive=N`) until UAT approval.
6. If lakehouse tables were replaced: trigger SQL endpoint metadata refresh (`POST /v1/workspaces/{ws}/sqlEndpoints/{id}/refreshMetadata`) and spot-check queryability.

## Hydration (GATED)

Foundation twin one-shot is on Fabric **2026-08-18**: orchestrator **22:13**
Central, analytics refresh **22:45** Central. Both expire at 23:59.
15-minute cron stays disabled on FD and Foundation. FD left OFF. History,
Zonda, and Salesforce outbound are not in this window. Disable-after-run
is required. Procedure: [`hydration-runbook.md`](hydration-runbook.md).

## API references

- Create: `POST /v1/deploymentPipelines`
- Assign: `POST /v1/deploymentPipelines/{id}/stages/{stageId}/assignWorkspace`
- Deploy: `POST /v1/deploymentPipelines/{id}/deploy`
