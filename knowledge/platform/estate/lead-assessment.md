# Lead engineer inheritance brief

**Author role:** Lead Data Engineer taking over an unknown estate  
**Date:** 2026-10-16  
**Tone:** operational honesty. No product marketing.

---

## Executive take (1 minute)

You inherited **two realities that do not fully agree**:

1. **A real Fabric production platform** that already runs Green Brick analytics: Foundation Development → Foundation promotion pair, governance workspace, mirrored NEWSTAR sources, Salesforce, Zonda, stage orchestrator, dbt-shaped analytics lakehouse, finance and operations reports. This is the business system of record for the rebuild.

2. **A software factory story in Foundation 2.0** that is young, thin, and mostly local. It has a clean SDK, policy gates, a `/factory` loop, and a synthetic local demo. It does **not** yet operate the live estate. CI for Foundation 2.0 is empty. The older Foundation ADO project still holds the large (~37 MB) engineering repo and a single "Jobsite Factory CI" pipeline.

If you treat Foundation 2.0 as "the platform," you will be wrong. If you treat GBP-Enterprise as "dead," you will also be wrong. **Cutover is incomplete. Parallel estates are live.**

---

## What is actually running (Confirmed)

### Fabric workspaces (tenant)

| Workspace | Role (as observed) | Rough size of problem |
|---|---|---|
| **Foundation Development** | Rebuild / proof workspace. Full stack. | Primary engineering surface. ~90+ items. |
| **Foundation** | Prod twin of FD. Missing web/BMX/market-intel slice. | Partial promotion. Drift is real. |
| **Foundation Governance** | Auditor/RBAC notebooks + `lake_house_governance` | Exists; not a report farm. Good. |
| **GBP-Enterprise** | Legacy medallion + ~93 pipelines (`pp_*`, dim/fact wrappers) | Still the fat legacy control plane. |
| **Operations** / **Operations-Dev** | Thin. EDW_Gold lakehouse + CustSat reports | Presentation leftovers. |
| **Finance** / **Finance-Dev** | Executive dashboards only | Thin presentation. |
| **DataSources** | Mirrored DB endpoints: BuildPro, HBLive, SPLive | Source mirrors live here. |
| Capacity Metrics / GitTest / My workspace | Noise / personal / tooling | Do not engineer against these. |

Capacity: **`gbpwus3fabric01` F64 Active** in West US 3 (Confirmed via `az`).

### Foundation Development shape (Confirmed)

**Landing / mirrors:** `HBLive`, `SPLive`, `BuildPro`, `dataverse_gbpdev` (name is a known landmine; see D11).  
**Domain lakehouses:** `lake_house_analytics`, `lake_house_salesforce`, `lake_house_zonda`, `lake_house_web`, `lake_house_buildermetrix`, `lake_house_pipeline`, `lake_house_scratch`.  
**Warehouses:** `warehouse_stage` (core), `warehouse_salesforce`.  
**Orchestration:** `pipeline_stage_orchestrator`, `pipeline_stage_wave_runner`, `pipeline_stage_history_load`, Salesforce orchestrator family, Zonda, web scrape, analytics refresh, harvest/mirror compare, sql runner.  
**Presentation:** Multiple `semantic_model_*` + `report_*` for finance and operations.  
**Activators:** failure reflexes for stage, Salesforce, Zonda, analytics refresh. Plus one unnamed dated Activator (cleanup candidate).

### Critical data-layer finding (Confirmed)

`warehouse_stage` exposes schemas: `raw`, `control`, `transform`, `analytics`, `dbo`.

There is **no `stage` schema with tables** under `Tables/stage` (path NotFound).  

Interpretation (Inferred, high confidence): "stage" in this estate is largely **control-driven load into transform**, not a populated `stage.*` table layer. The D0 vocabulary says raw/stage/control/transform/analytics. Live inventory shows **stage as process, not as a table schema**. That gap will confuse every new hire who reads the docs literally.

`control` is healthy (~31 tables) including `stage_load_config`, audit tables, web scrape control, CustSat VOC config.  
`transform` has the core EDW port (~22 entities including hist).  
`lake_house_analytics.operations` has ~77 tables (Confirmed). Includes D19 `market_dim_*` exceptions and web/market objects.

`dbo` under warehouse_stage: empty of tables (good; matches D0 intent).

### FD vs Foundation drift (Confirmed)

Dev-only (not in Foundation twin): BuilderMetrix LH, web LH + pipelines/notebooks, market intelligence + competitor + web listing semantic models/reports, VOC notebook/pipeline, pipeline seed/watermark notebooks, sample Lots semantic models/dashboard, one orphan Activator.

**Prod is behind Dev on market/web/BMX.** That is either intentional (D18/D19 say no twin yet) or promotion debt. Treat as intentional until someone proves otherwise, but document it so nobody "fixes" prod by copying without reading D18/D19.

### Legacy GBP-Enterprise (Confirmed)

~175 workspace items, **~93 DataPipelines**. Naming is the old world: `pp_load_stg_to_dim_*` with audit/full/no_audit variants, `EDW_Silver` / `EDW_Gold` warehouses, Dataverse gbpdev+gbpprod, Zonda notebooks with `nb_` prefixes. This is exactly the fleet Foundation was built to obsolete. **It is still there.** Do not delete it. Do not pretend the orchestrator in FD already replaced every consumer.

### Azure around Fabric (Confirmed)

Subscription **Production-Fabric** (`ef9cbd96-…`) default.  
RG `rg-gbpartner-fabric`: Fabric capacity, Key Vault `gb-fabric-keyvault`, storage (`gbpintegrationfiles`, `stfoundationexport`), Function App `func-foundation-paginated-export` + App Insights.  
Also RGs for TM1, network, data, BuilderMetrix SQL MI (`rg-bmx-sqlmi-wus3`).

**Key Vault secret list: Forbidden** for this caller (Confirmed). You can see the vault exists; you cannot inventory secrets. That is an access gap for a lead who needs to understand credential topology.

Other subscriptions exist: Platform, Production, Non Production, Azure subscription 1. Not fully mapped this pass.

### Azure DevOps (Confirmed)

| Project | Repo size | Pipelines | Role |
|---|---|---|---|
| **Foundation** | ~37 MB | 1: "Jobsite Factory CI" | Real engineering monorepo (legacy path) |
| **Foundation 2.0** | ~71 KB | **none** | New SDK/factory seed; just born |
| **TM1** | (not inspected) | — | Adjacent product |

Two Foundation projects is a **governance smell**. People will push to the wrong place. Pick a system of record and say it out loud. Today the **live Fabric knowledge and dbt history still live in the big Foundation repo**; Foundation 2.0 is the rebuild of the *engineering platform*, not a full cutover of content.

---

## What Foundation 2.0 actually is (Confirmed from this checkout + demo)

Strengths:

- Deterministic SDK + policy engine that **denies** unapproved prod mutation without an LLM.
- ADF IR + modernization assessment path on fixtures.
- Factory runtime with persistent jobs, bounded repair, approve/rework.
- Local `demos/local_orders` with independent expected aggregates.
- Cursor agents/skills aligned to Foundation naming (not ADEF).

Weaknesses (say them plainly):

- **Does not discover or operate the live estate yet.** No live Fabric inventory command was required to ship M0–M11; this knowledge pass is the first real connection.
- Knowledge folder was empty except decisions until today.
- No ADO pipelines in Foundation 2.0.
- SSH git to ADO still broken; HTTPS+az works.
- Jobsite brand is "sunset" in docs while the only CI pipeline in the sibling project is still named Jobsite Factory CI.
- On-prem SQL MCP (`user-gbp-onprem-sql-readonly`) is in **error** state; Encompass (D3) remains dark.

---

## Architectural truths the docs understate

1. **Medallion is not gone.** It lives in GBP-Enterprise and Operations EDW_Gold. Foundation bans bronze/silver/gold *in new work*. Legacy still uses those names.
2. **`dataverse_gbpdev` in Foundation is a trap.** D11 documents why. Rename without proc edits will break transform.
3. **Full-volume Dev (D5)** means FD is not a sandbox. Treat FD data as production-grade volume with non-prod promotion semantics.
4. **Shared analytics lakehouse (D15)** is real and busy. Domain boundaries are folders/tags, not separate lakehouses.
5. **Naming debt is mixed.** New objects mostly follow D13. Exceptions (`market_dim_*`) are explicit. Sample items (`Lots of Samples`, `LotsTest`, dated Activator) look like leftover experiments in FD.

---

## Risk register (lead view)

| Risk | Severity | Evidence |
|---|---|---|
| Dual-repo / dual-ADO confusion | High | Foundation (~37MB) vs Foundation 2.0 (~71KB); CI only on old name |
| Incomplete cutover; legacy pipeline fleet still live | High | ~93 `pp_*` pipelines in GBP-Enterprise |
| FD→Foundation drift on web/market/BMX | Medium | Confirmed item diff |
| Stage schema missing vs documented layers | Medium | `Tables/stage` NotFound |
| Key Vault RBAC blind spot for operator | Medium | Forbidden on secret list |
| On-prem SQL / Encompass unknown | Medium | MCP error; D3 open |
| Orphan sample artifacts in FD | Low | Lots*/dated Activator |
| Claiming Factory "runs the platform" | High if believed | Local demo ≠ live orchestration |

---

## What I would do in the first two weeks (recommendation)

Not asking permission; stating the job:

1. **Declare system of record:** which ADO project owns Fabric engineering for the next 90 days. Document the bridge.
2. **Schedule a weekly `fab` inventory refresh** into `knowledge/inventory/` (read-only). Automate later.
3. **Map `stage_load_config` → orchestrator → transform tables** with one entity end-to-end (sale or lot). Prove the metadata story with evidence.
4. **Parity report FD vs Foundation** for promoted items only; leave D18/D19 items as intentional gaps.
5. **Fix operator access:** Key Vault list (or document who owns secrets), repair on-prem SQL MCP or replace with documented jump host.
6. **Do not** delete GBP-Enterprise pipelines. **Do not** promote web/BMX until D18/D19 say so.
7. Keep Foundation 2.0 Factory as the **engineering control plane**; wire it to live discovery next, not more dashboard chrome.

---

## Evidence pointers

- Raw dumps: [`../inventory/`](../inventory/)
- Decisions: [`../decisions/README.md`](../decisions/README.md)
- Access gaps: [`../operations/access-gaps.md`](../operations/access-gaps.md)

**Bottom line:** The Fabric rebuild is real and advanced. The engineering factory in Foundation 2.0 is real but early. Your job is to connect them without setting the legacy estate on fire.
