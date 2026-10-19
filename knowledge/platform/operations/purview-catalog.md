# Catalog, lineage, and upstream visibility (plan)

**Updated:** 2026-08-13  
**Status:** Plan only. **Do not create Azure Purview or enable scans until an
explicit go-ahead.** There is no hurry. Nothing in this file is a schedule.

**Confirmed 2026-08-13:** subscription `Production-Fabric`
(`ef9cbd96-c21e-4800-a898-fee8914dd532`) has **no** Purview or data-catalog
resource. Azure SQL `gbpsql01` exists in `rg-wus3-data`.

## What this is for

Give IT Audit and data owners a durable view of **upstream systems**
(NSE / HBLive, BuildPro, NewStar / SPLive, Dataverse, Salesforce, Zonda) and
of **Foundation consumption** (dbt analytics, lakehouse, Finance semantic
models). Split the problem:

| Layer | Tool | What it can show |
|---|---|---|
| Item discovery and one-hop bindings | Fabric **OneLake catalog** + **lineage view** | Workspaces, items, SM data sources, one hop outside the workspace |
| Estate catalog, glossary, classification | **Microsoft Purview** Unified Catalog | Fabric items + scanned Azure SQL / Dataverse / Salesforce metadata |
| Table-level transform contract | **dbt** + `knowledge/lineage/` | `HBLive.rems.*` through `transform.sp_load_*` to `analytics.*` |
| SQL source vs mirror freshness | `pipeline_mirror_compare` | Column/row drift vs `gbpsql01` into `control.azure_vs_mirrored_db_audit_log` |

Purview does **not** replace dbt for IPE table lineage. Microsoft documents
that Fabric scans do not attach external data sources as upstream of
non-Power BI items, do not do cross-workspace lineage for those items, and
do not do notebook-to-pipeline lineage. Lakehouse table metadata scan exists;
table-level lineage does not.

## Target architecture (when executed)

```
gbpsql01 (BuildPro, HBLive, SPLive, Encompass)
  -> DataSources mirrored DBs (BuildPro, HBLive, SPLive; Encompass not mirrored)
  -> Enterprise lakehouses -> FD/Foundation shortcut lakehouses in raw/
  -> warehouse_stage transform.sp_load_*
  -> analytics dbt views -> lake_house_analytics
  -> Finance / ops semantic models

Purview Data Map scans:
  1. Fabric tenant (same Entra tenant e4a6f415-...)
  2. Azure SQL gbpsql01 databases
  3. Dataverse (later)
  4. Salesforce (later; outbound stays IsActive=N)

OneLake catalog stays the in-Fabric workbench (Explore / Govern / Secure).
```

Workspaces to include in the Fabric scan scope (confirmed IDs):

| Workspace | ID | Why |
|---|---|---|
| Foundation Development | `40502864-6ece-49b5-807f-6f7c11d1b3e1` | Dev twin |
| Foundation | `7c1850c1-821f-4fc7-a823-c186516023c6` | Prod twin |
| DataSources | `70ffb171-dc73-4b17-b7b4-e8dea16b925a` | SQL mirrors |
| GBP-Enterprise | (live name) | Legacy books path until cutover |
| Finance | (live name) | Current IPE reports |

Do not scan personal workspaces. Start scoped to Foundation + DataSources if
scan volume or "too many requests" is a concern.

## Phase 0. Preconditions (gated)

Needed before `--apply` on the provision script:

1. Written go-ahead (this plan is not permission to spend).
2. Cost owner sign-off for a Purview account in `rg-gbpartner-fabric`, West US 3.
   Confirm SKU / billing with platform (Randy). Do not guess a SKU.
3. Fabric tenant admin for:
   - Metadata scanning / admin APIs
   - Allow service principals to use read-only admin APIs (scoped to a group)
   - OneLake: users can access data stored in OneLake with apps external to Fabric
4. Entra ability to create a security group and add the Purview managed identity.
5. Azure SQL scan: a credential that can `VIEW DEFINITION` on BuildPro, HBLive,
   SPLive (Key Vault secret; Purview MSI Get/List on the vault). Prefer the
   same `gb-fabric-keyvault`. Do not embed SQL auth in a pipeline name.
6. Identity work already queued (not blocking catalog, but blocking clean
   runtime): WI group Key Vault Secrets User, `foundation-fabric-automation` SP.

## Phase 1. Fabric-native (no new Azure resource)

Can be done anytime; no Purview required.

1. Bookmark OneLake catalog (Explore / Govern / Secure) for Foundation
   Development and Foundation.
2. For each in-scope Finance semantic model, open **lineage view** and save
   the binding (Foundation Lake / FD Lake, Dataverse). That is the IPE
   "what does this report read" screenshot.
3. Keep `knowledge/lineage/overview.md` and dbt `sources.yml` as the
   table-level map. Refresh those when in-scope models change (git, once ADO
   is connected).
4. Leave `pipeline_mirror_compare` **schedule OFF**. When hydration is
   approved, run it on demand first; only then consider a Central daily
   window. Enterprise's copy expired and a manual run Failed; FD copy must
   be connection-checked before trust.

## Phase 2. Create Microsoft Purview (gated)

Script (dry-run by default): [`automation/provision_purview.sh`](../../automation/provision_purview.sh)

Intended names (D13 / existing `gb-*` pattern):

| Thing | Value |
|---|---|
| Resource group | `rg-gbpartner-fabric` |
| Region | westus3 |
| Account name | `gb-purview` (globally unique; script checks) |
| Tenant | `e4a6f415-d627-4422-b4d5-39090a5a4486` |

After create:

1. Note the Purview managed identity object ID.
2. Create Entra group `GB Fabric Purview Scanners` (or reuse an existing
   Fabric API group if tenant settings already allow it). Add the Purview MSI.
3. Fabric Admin portal: enable read-only admin APIs for that group; enable
   metadata scanning.
4. Grant Purview MSI **Key Vault Secrets User** on `gb-fabric-keyvault` if
   SQL / Salesforce scans will use secrets. Randy must run the role
   assignment (same block as Zonda).

## Phase 3. Register and scan (gated, after Phase 2)

Order:

1. **Microsoft Fabric** source, same-tenant, Azure IR, managed identity.
   Scope: Foundation Development, Foundation, DataSources. Run one full scan.
   Confirm items appear under Unified Catalog, Browse, Microsoft Fabric.
2. **Azure SQL Database** sources on `gbpsql01.database.windows.net`:
   `HBLive`, `BuildPro`, `SPLive`. Full scan. Encompass is a later add
   (no Fabric mirror today; catalog can still scan the SQL database).
3. Spot-check: HBLive database in Purview vs DataSources `HBLive` mirrored
   database vs FD `raw/HBLive` shortcut lakehouse. Three assets, one system.
   Document that relationship in the system narrative; Purview will not draw
   it automatically.
4. Dataverse and Salesforce scans: after identity and UAT connection work.
   Salesforce outbound stays `IsActive=N`.

Scan cadence: weekly incremental is enough. Do not turn on aggressive
concurrent scans (Microsoft: "Too many requests").

## Phase 4. Unified Catalog for SOX / IT Audit

Only after scans return data:

1. Governance domain: **Foundation** (or Homebuilding Finance IPE).
2. Glossary terms for in-scope subjects: sale, closing, lot financials,
   operating unit, net revenue.
3. Data products (inferred until Controller confirms IPE list):
   - Finance weekly sales / unit
   - Lot financials / SGM
   - General ledger det
4. Owners: data owner (Controller or Finance), technical owner (Fabric
   Architect).
5. Collection policy: do not catalog scratch, `_backup_`, or personal
   workspaces.

## Phase 5. Operational upstream health (not Purview)

| Check | Object | When |
|---|---|---|
| Mirror vs SQL | `pipeline_mirror_compare` | On-demand until hydration; then consider daily Central |
| Load success | `control.audit_sp_control` | Every orchestrator run |
| Shortcut presence | FD/Foundation `raw` lakehouses | After any promote |
| Encompass | Still no mirror | Separate decision; not part of this catalog standup |

## Non-goals

- Do not expect Purview to prove `jobsales` -> `sale_obt` column lineage.
- Do not scan GBP-Enterprise-Dev noise (`_test`, `_bkp`) if a scoped scan
  can exclude it.
- Do not enable Purview DLP or sensitivity auto-labeling in the first pass
  (separate security design).
- Do not create Purview in a hurry ahead of identity and cost sign-off.
- Do not touch Enterprise mirrors or `gbpsql01` public-network settings as
  part of catalog setup (D12; network change is a separate identity item).

## Execute later

```bash
# Dry-run (default): existence check + print intended names
bash automation/provision_purview.sh

# Only after written go-ahead and cost sign-off:
bash automation/provision_purview.sh --apply
```

Register/scan steps after `--apply` are portal / Purview Data Map UI (Fabric
tenant + Azure SQL). There is no Fabric CLI for those registrations today.

## Related

- Lineage map: [`knowledge/lineage/overview.md`](../lineage/overview.md)
- Identity / KV: [`identity.md`](identity.md)
- Mirror compare: [`knowledge/pipelines/utilities.md`](../pipelines/utilities.md)
- SOX control program: canvas `sox-it-audit-foundation`
