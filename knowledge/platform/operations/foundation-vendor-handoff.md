# Foundation platform handoff (vendor)

**Created:** 16 October 2026  
**Audience:** External vendors working on the Green Brick **Foundation** Fabric rebuild  
**Scope:** Platform topography, naming, decided architecture, and engineering rules.  
**Out of scope:** Internal delivery tooling, chat workflows, and operator-only automation.

When this summary conflicts with the Foundation git repository, **the repository wins**.

---

## 1. External references

Use these as primary product documentation. Green Brick does not duplicate them in this handoff.

| Topic | Reference |
| --- | --- |
| Repository access | [Azure DevOps: grbk / Foundation](https://dev.azure.com/grbk/Foundation/_git/Foundation) |
| Microsoft Fabric | [Microsoft Fabric documentation](https://learn.microsoft.com/en-us/fabric/) |
| Fabric CLI | [Fabric CLI (fab)](https://learn.microsoft.com/en-us/fabric/data-engineering/fabric-cli) |
| Azure CLI | [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/) |
| dbt on Fabric | [dbt-fabric adapter](https://docs.getdbt.com/docs/core/connect-data-platform/fabric-setup) |
| Open Data Contract Standard | [ODCS](https://bitol-io.github.io/open-data-contract-standard/) |

**Clone and workspace root:**

```bash
git clone https://dev.azure.com/grbk/Foundation/_git/Foundation
cd Foundation
```

Open the **Foundation** folder as the IDE workspace root (not a parent directory).

---

## 2. What Foundation is

| Term | Meaning |
| --- | --- |
| **Foundation** | Git monorepo for the Fabric rebuild: dbt analytics, automation scripts, knowledge, and guardrails |
| **Foundation Development (FD)** | Fabric workspace where **new** platform work is built, tested, and proven |
| **Foundation** (workspace) | Production twin paired with FD via deployment pipeline (naming stays spelled **Foundation Development** / **Foundation**, not lowercase product rename) |
| **Foundation Governance** | Separate workspace for audit/inventory snapshots (D17). Not a Dev/Prod pair. Not for department reports |
| **Legacy / domain workspaces** | Operations, Finance, GBP-Enterprise, Operations-Dev, and similar **existing** estates. Out of bounds for vendor cutover unless Green Brick gives a **written, item-level** instruction |

**Standing order (D12):** Rebuild by **copy and prove in Foundation Development**. Do **not** delete, retire, disable, overwrite, or cut over production or legacy Fabric items unless Green Brick names the **exact item and action in writing for that change**. Design documents and migration plans are **not** permission to destroy.

---

## 3. Platform topography (Fabric)

### 3.1 Layer model (target state)

Layers are **schemas and workspace folders**, not medallion labels in new names.

| Layer | Role | Why it exists |
| --- | --- | --- |
| **raw** | Landed, source-aligned data | Isolate ingestion from conformed models |
| **stage** | Conformed, integrated staging | Shared integration before consumption |
| **control** | Audit, orchestration metadata, load config | Operational plane separate from business tables |
| **transform** | Conformed transform (former “silver” behavior) | Business rules without consumption sprawl |
| **analytics** | Consumption-ready models and presentation | Reports, semantic models, and agents read here |

**Rule (D0):** No new **business** objects in **`dbo`**. Use the layer schemas above.

### 3.2 Foundation Development workspace layout (folders)

Organize FD artifacts by layer (D13):

| Folder | Contents |
| --- | --- |
| `raw/` | Ingestion pipelines, raw lakehouses |
| `stage/` | Stage loads, stage warehouses |
| `analytics/` | Presentation only; departments nest as `analytics/<department>` |
| `utilities/` | Platform tooling (refresh runners, scratch, dbt jobs). Not business analytics |

### 3.3 Lakehouses and warehouses (in-Foundation naming)

| Object pattern | Example | Notes |
| --- | --- | --- |
| `lake_house_<subject>` | `lake_house_analytics`, `lake_house_salesforce`, `lake_house_web` | D15: one **`lake_house_analytics`** for all domains unless capacity forces split |
| `warehouse_<subject>` | `warehouse_stage`, `warehouse_salesforce` | Stage and domain warehouses as decided |
| `pipeline_<domain>_<object>` | `pipeline_salesforce_ingest` | No `pl_` acronym |
| `notebook_<domain>_<object>` | | No `nb_` acronym |
| `semantic_model_<domain>_<subject>` | | No `sm_` acronym |
| `variable_library_<subject>` | | |
| `data_agent_<domain>_<subject>` | | FD-only POCs until promote (e.g. D16 CustSat) |

**Banned in new FD work:** `EDW_*`, `dim_*`, `fact_*`, `vw_*`, and tool acronyms `pl_`, `lh_`, `wh_`, `sm_`, `nb_`, `ai_`, `da_`.

### 3.4 dbt (consumption layer)

| Item | Value |
| --- | --- |
| Project name | **`foundation`** |
| Role | Owns analytics / consumption models first (D13) |
| Validation | `dbt compile` (or project equivalent) before merge when models change |

### 3.5 Governance workspace (D17)

**Foundation Governance** holds auditor-oriented snapshots and inventory. Do **not** place Finance or department presentation reports there. Do **not** treat it as a second FD/Prod pair.

---

## 4. Repository topography (git)

| Path | Role |
| --- | --- |
| `knowledge/` | Architecture, decisions, operations runbooks |
| `knowledge/decisions/README.md` | Decision log (D-ids) |
| `dbt/` | dbt project `foundation` |
| `automation/` | Deploy, rebuild, and control scripts |
| `rebuild-plan/` | Rename map and rearchitecture proposal |
| `snapshots/` | Local Fabric exports (often gitignored on clones) |
| `workspaces/`, `fabric/` | Workspace-linked exports where used (sensitive to path policy) |

**Decisions and rename spellings:** [`knowledge/decisions/README.md`](../decisions/README.md), [`rebuild-plan/rename-map.md`](../rebuild-plan/rename-map.md) (D7).

---

## 5. Table and view naming (D0, D13)

| Rule | Detail | Why |
| --- | --- | --- |
| Plain names | Reader knows what the object holds without opening it | Replaces opaque `dim_` / `fact_` / `vw_` |
| Pattern | `<subject>[_<qualifier>]_<shape>[_<period>]` | Consistent consumption and transform |
| Shapes | `obt`, `sum`, `det`, `hist`, `map` | Grain is visible in the name |
| Reference entities | No shape marker: `company`, `project`, `calendar` | Former dimensions as entities |
| Period suffix | Last when time-bound: `sales_sum_weekly` | Avoid ambiguous grains |
| History (D14) | `*_hist` with ported SCD2 pattern (`record_hash_key`, effective dates) | Parity with EDW; no redesign during rebuild |

---

## 6. Decided architecture (D-ids)

Vendors **must honor** decided ids. Do **not** reverse or “improve” them without a new decision entry.

| ID | Decision | Why |
| --- | --- | --- |
| **D0** | Layer schemas and naming shapes; no business objects in `dbo` | Clean platform boundary |
| **D1** | Salesforce inside Foundation stack (`lake_house_salesforce`, etc.); no separate `gbp-salesforce-*` workspace | Single product stack |
| **D4** | Finance from shared analytics layer; no dedicated finance warehouse | One presentation strategy |
| **D5** | FD carries full-volume data for rebuild parity | Verification against Enterprise |
| **D6** | Alerts use `foundation_data_monitoring@greenbrickpartners.com` until permanent DL | Operational contact |
| **D7** | Rename-map spellings (e.g. SGM spelled out) | Business vocabulary |
| **D8** | Keep `sale_transfer` TRUNCATE & LOAD and `fiscal_period` FULL cadence unless explicitly revisiting | Cutover-stable loads |
| **D9** | Stage retry `retry_count = 1`, 10 min timeout (standard entities) | Bounded retries |
| **D10** | Metadata-driven orchestrator; no new InvokePipeline wrapper fleet | Reduce pipeline sprawl |
| **D12** | No prod destroy without explicit written item + action | Safety and audit |
| **D13** | Workspace names, dbt project name, spelled Fabric prefixes, folder layout | One naming system |
| **D14** | Keep ported `*_hist` SCD2 pattern | Provable EDW parity |
| **D15** | One `lake_house_analytics` for domains | Avoid lakehouse proliferation |
| **D16** | CustSat data agent FD-only until promote ask | POC containment |
| **D17** | Governance only in Foundation Governance workspace | Separation of audit vs build |
| **D18** | BuilderMetrix → `lake_house_buildermetrix` under FD `raw`; no schedule/twin/analytics until named | Controlled landing |
| **D19** | Web scrape lands under FD raw/web pattern and `warehouse_stage` control tables; never `dbo`; schedules off until named consumption model | Scrape as source landing policy |

**Open (do not close without Green Brick):**

| ID | Status |
| --- | --- |
| **D2** | Audit-variant wrappers (likely moot for Foundation orchestrator) |
| **D3** | Encompass mirror deferred |
| **D11** | Keep `dataverse_gbpdev` naming until cutover bundle |

Full log: [`knowledge/decisions/README.md`](../decisions/README.md).

---

## 7. Engineering rules for vendor deliverables

| Rule | Requirement | Why |
| --- | --- | --- |
| **Default write workspace** | Foundation Development only | D12 |
| **Live Fabric changes** | Document steps; prove with `fab get` / `fab ls` / `fab exists` read-back against FD | Evidence, not narrative |
| **Schedules** | Do not enable Fabric job schedules unless Green Brick asks in writing for that change | Unattended run risk |
| **Credentials** | Key Vault and workspace identity preferred; no secrets in git | Security |
| **SQL exploration (HBLive on GBP-SQL03)** | Read-only; **`WITH (NOLOCK)`** on every table/view | Estate standard for busy OLTP |
| **Python changes** | `python -m compileall` on touched packages under `automation/` when applicable | Catch syntax errors |
| **Contracts** | ODCS YAML for new interfaces when Green Brick requests contract-first delivery | Versionable agreements |
| **Style** | No em dashes or en dashes in deliverables; label **Confirmed** vs **Inferred** evidence | Consistent audit narrative |
| **Commits** | Follow Green Brick PR/branch instructions for the engagement | ADO is system of record |

---

## 8. Environment boundaries

| Environment | Vendor default | Escalation |
| --- | --- | --- |
| Foundation Development | Build, test, publish proofs here | N/A |
| Foundation (prod workspace twin) | No direct mutation unless engagement letter says otherwise | Written approval per item |
| Legacy workspaces (Operations, Finance, GBP-Enterprise, …) | Read for analysis only | Explicit destroy/cutover instruction per D12 |
| Foundation Governance | Read/copy for audit patterns only | Do not use for department dashboards |
| On-prem SQL | Read-only SELECT unless separate DBA engagement | No prod DDL |

---

## 9. Validation before handback

| If you changed | Show |
| --- | --- |
| `dbt/` models | Successful `dbt compile` (or documented equivalent) |
| `automation/**/*.py` | Successful `compileall` on touched trees |
| Fabric items in FD | Item id or `fab` read-back naming **Foundation Development** |
| Naming | Compliance with Section 5 and D13 bans |

---

## 10. Out of scope for typical vendor SOW

| Item | Why |
| --- | --- |
| Production or legacy workspace cutover | D12; separate explicit authorization |
| Fictional demo datasets (e.g. retail showcase products) | Not Green Brick domains |
| Unapproved Azure spend (new capacity, SKUs) | Cost and architecture approval |
| Identity production cutover (Entra, SQL auth removal) | Separate infrastructure workstream |

---

## 11. Further reading inside the repo (optional)

Vendors with repo access may read these for depth. They are **not** required to use internal operator tooling.

| Document | Content |
| --- | --- |
| [`README.md`](../../README.md) | Clone, CLI smoke checklist |
| [`AGENTS.md`](../../AGENTS.md) | Engineering norms summary |
| [`knowledge/rebuild-plan/rearchitecture.md`](../rebuild-plan/rearchitecture.md) | Rebuild rationale and naming examples |
| [`knowledge/operations/analytics-setup.md`](analytics-setup.md) | Analytics / FD setup |
| [`knowledge/operations/deployment-pipeline.md`](deployment-pipeline.md) | FD / Foundation promotion |

---

*End of vendor handoff. Questions on decisions or scope: Green Brick Foundation platform owner before changing prod or legacy Fabric.*
