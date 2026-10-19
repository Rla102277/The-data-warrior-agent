# Green Brick Foundation Environment

**Documented:** 2026-07-13  
**Working root:** `~/Documents/Projects/Foundation`  
**Authoritative live sources:** Fabric CLI (`fab`), Azure CLI (`az`)  
**Evidence policy:** Sections mark **Confirmed** vs **Inferred**. Inferred items are labeled and should be validated before acting on them.

---

## 1. Identity and tenancy (Confirmed)

| Field | Value |
|---|---|
| Entra tenant ID | `e4a6f415-d627-4422-b4d5-39090a5a4486` |
| Azure subscription name | Production-Fabric |
| Azure subscription ID | `ef9cbd96-c21e-4800-a898-fee8914dd532` |
| Fabric portal | `app.fabric.microsoft.com` |
| Documented operator account | `rarchambault@greenbrickpartners.com` |
| Fabric CLI principal ID | `7c223003-ec54-4d5e-b015-16781eaf8650` |
| Fabric CLI app ID | `5814bfb4-2705-4994-b8d6-39aabeb5eaeb` |

Capacity admins on `gbpwus3fabric01` (Confirmed):

- `ppurviance@GreenBrick1.onmicrosoft.com`
- `randerson@greenbrickpartners.com`
- `automations@GreenBrick1.onmicrosoft.com`
- `bcorbet@GreenBrick1.onmicrosoft.com`
- `rarchambault@greenbrickpartners.com`

---

## 2. Local workstation (Confirmed)

| Component | Value |
|---|---|
| Host | Randys-MacBook-Pro.local |
| OS | macOS 26.5.2 (Build 25F84), Darwin 25.5.0, arm64 |
| Shell | `/bin/zsh` |
| Fabric CLI | `fab` 1.6.1 at `~/.local/bin/fab` |
| Azure CLI | `az` 2.87.0 |
| Python | 3.11.9 |
| PowerShell 7 (`pwsh`) | Not installed on this workstation |

Cursor persona for this repo: `.cursor/rules/fabric-architect.mdc` (`alwaysApply: true`).

---

## 3. Local Foundation layout (Confirmed)

```
~/Documents/Projects/Foundation/
├── .cursor/rules/fabric-architect.mdc
├── automation/export-fabric-live.sh
├── docs/                 (empty placeholder)
├── documentation/        (empty placeholder)
├── fabric/               (empty placeholder)
├── foundation/           (empty placeholder)
├── knowledge/            (documentation tree; see section 9)
├── repos/                (empty placeholder)
├── snapshots/            (Fabric export snapshots)
└── workspaces/           (empty placeholder)
```

Git repository is initialized at the Foundation root.

### Snapshot convention

- Path: `snapshots/snapshot_YYYY-MM-DD_HH-MM/`
- Symlink: `snapshots/latest` should point at the newest complete snapshot
- Export script: `automation/export-fabric-live.sh`
  - Lists workspaces with `fab ls`
  - Exports each `*.Workspace` with `fab export <name> -o <dir> -a -f`
  - Skips `My workspace.Personal`
  - Refreshes `latest` only after the full run completes

### Snapshot status as of 2026-07-13 (Confirmed)

| Snapshot | Contents | Notes |
|---|---|---|
| `snapshot_2026-07-09_15-33` | Empty | Failed early (`fab workspace list` invalid) |
| `snapshot_2026-07-09_15-34` | Empty workspace folders only | Current `latest` target; no item definitions |
| `snapshot_2026-07-09_15-39` | Partial item exports | Stopped mid-run; richest local artifact set |

`latest` currently points at `snapshot_2026-07-09_15-34` (empty shells). Prefer live `fab` or the partial `15-39` tree until a complete export finishes.

Partial `15-39` folders present: Audit-Dev, DataSources, Finance, Finance-Dev, GBP-Enterprise-Dev (GBP-Enterprise-Dev may be incomplete).

---

## 4. Azure resource groups (Confirmed)

Subscription: Production-Fabric (`ef9cbd96-c21e-4800-a898-fee8914dd532`)

| Resource group | Location | Role (summary) |
|---|---|---|
| `rg-gbpartner-fabric` | westus3 | Fabric capacity, Key Vault, NSG, integration storage |
| `rg-wus3-data` | westus3 | Azure SQL (`gbpsql01`) and private endpoints |
| `rg-wus3-network` | westus3 | VNet, private DNS, route table, DNS resolver |
| `NetworkWatcherRG` | westus3 | Network Watcher |
| `gbpartner-asc-export` | southcentralus | Defender ASC automation `ExportToWorkspace` |
| `VisualStudioOnline-...` | centralus | Visual Studio Online related (not Fabric core) |

### 4.1 `rg-gbpartner-fabric`

| Name | Type | Location |
|---|---|---|
| `gbpwus3fabric01` | Microsoft.Fabric/capacities (SKU F32, Active) | westus3 |
| `gb-fabric-keyvault` | Microsoft.KeyVault/vaults (Standard, RBAC enabled) | westus3 |
| `GBP-nsg-Fabric` | Microsoft.Network/networkSecurityGroups | westus3 |
| `gbpintegrationfiles` | Microsoft.Storage/storageAccounts (StorageV2, Standard_RAGRS, HTTPS only) | southcentralus |

### 4.2 `rg-wus3-data`

| Name | Type |
|---|---|
| `gbpsql01` | Microsoft.Sql/servers (`gbpsql01.database.windows.net`, public network access Enabled) |
| `gbpsql01/BuildPro` | SQL database |
| `gbpsql01/HBLive` | SQL database |
| `gbpsql01/SPLive` | SQL database |
| `gbpsql01/Encompass` | SQL database |
| `gbpsql01/master` | SQL database |
| `pe-wus3-sql-db` | Private endpoint (+ NIC) |
| `pe-wus3-sql-db1` | Private endpoint (+ NIC) |

### 4.3 `rg-wus3-network`

| Name | Type | Notes |
|---|---|---|
| `gbpartner-vnet-wus3-prod` | Virtual network | Address space `10.3.0.0/20` |
| Subnets | `data`, `default`, `dns-resolver` | `dns-resolver` = `10.3.2.0/28` |
| `privatelink.database.windows.net` | Private DNS zone (+ VNet link) | |
| `rt-wus3-prod-fabric` | Route table | |
| `dns-resolver-fabric` | DNS resolver (+ inbound endpoint `inbound-ddc`) | |

---

## 5. Fabric capacity (Confirmed)

| Field | Value |
|---|---|
| Name | `gbpwus3fabric01` |
| Resource group | `rg-gbpartner-fabric` |
| Region | West US 3 |
| SKU | F32 (Fabric tier) |
| State | Active / provisioning Succeeded |
| Bound workspaces | All listed `*.Workspace` items below |

---

## 6. Fabric workspaces (Confirmed)

All capacity-bound workspaces use `gbpwus3fabric01` in West US 3.

| Workspace | ID | Item count | Role (descriptive) |
|---|---|---|---|
| Audit-Dev.Workspace | `39854263-5bae-4eb2-a9b6-6ba274d7476d` | 9 | RBAC / audit notebooks and lakehouse |
| DataSources.Workspace | `70ffb171-dc73-4b17-b7b4-e8dea16b925a` | 6 | Mirrored DBs for BuildPro, HBLive, SPLive |
| Finance-Dev.Workspace | `d9293f73-accc-45cb-bb1c-9fab65256758` | 25 | Finance reports / semantic models (dev) |
| Finance.Workspace | `9b62026a-4675-4ddb-a0ad-2177f597f114` | 4 | Finance executive reports (prod) |
| GBP-Enterprise-Dev.Workspace | `bf1c626e-e497-4fa3-b5ff-510be3158541` | 167 | Primary EDW + pipelines (dev) |
| GBP-Enterprise.Workspace | `855ce463-047f-4fd0-9e3e-5ed6faccee5e` | 171 | Primary EDW + pipelines (prod) |
| GitTest.Workspace | `520d9dad-b35b-4c5e-82c2-1764a234e454` | 1 | Git / pipeline test |
| Microsoft Fabric Capacity Metrics.Workspace | `d376af32-9a7f-401e-b836-cabf63009545` | 2 | Capacity metrics report / model |
| Operations-Dev.Workspace | `41415a12-1442-4a58-ae6d-686109fd7108` | 3 | Operations gold lakehouse (dev) |
| Operations.Workspace | `6c8f8e5a-ccac-40c0-ae3e-2abb84309f35` | 12 | Operations gold + RTI sample (prod) |
| My workspace.Personal | `5c7956e6-4043-4669-9fd8-4cff84eb84d0` | n/a | Personal; no capacity; export script skips |

Detail by workspace: `knowledge/workspace-map/workspaces.md`

### Aggregate item types across capacity workspaces (Confirmed)

Approximate totals from live `fab ls` (includes SQLEndpoint and similar sibling items):

| Type | Approx count |
|---|---|
| DataPipeline | 181 |
| Notebook | 38 |
| Lakehouse | 30 |
| SQLEndpoint | 33 |
| SemanticModel | 43 |
| Warehouse | 21 |
| Report | 18 |
| Reflex | 10 |
| MirroredDatabase | 3 |
| PaginatedReport | 3 |
| Dataflow | 4 |
| Eventstream / Eventhouse / KQL* / VariableLibrary | present in Enterprise and Operations |

---

## 7. Data platform shape (Confirmed names; Inferred layers)

### 7.1 Confirmed stores in GBP-Enterprise / GBP-Enterprise-Dev

**Lakehouses (examples):** `gbp_lakehouse`, `BuildPro`, `HBLive`, `SPLive`, `Salesforce`, `Zonda`, `dataverse_gbpdev`, `dataverse_gbpprod`, plus several Dataflows staging lakehouses.

**Warehouses (examples):** `EDW_Silver`, `EDW_Gold`, `DataflowsStagingWarehouse`, `Salesforce_WH`, `Salesforce_WH_UAT`, `WebsiteData`, plus staging warehouses.

**Mirrored databases (DataSources):** `BuildPro`, `HBLive`, `SPLive` (aligned with Azure SQL DBs of the same names on `gbpsql01`).

**Operations workspaces:** `EDW_Gold.Lakehouse` (Dev and Prod).

### 7.2 Medallion interpretation (Inferred)

Naming strongly suggests:

| Layer | Likely stores | Confidence |
|---|---|---|
| Bronze / landing | `gbp_lakehouse`, mirrored SQL (`BuildPro`/`HBLive`/`SPLive`), source lakehouses (`Zonda`, Salesforce, Dataverse) | Inferred from names |
| Silver | `EDW_Silver.Warehouse` | Inferred from name |
| Gold | `EDW_Gold.Warehouse` (Enterprise), `EDW_Gold.Lakehouse` (Operations) | Inferred from names |

This matches the Foundation rule preference (bronze Lakehouse, silver Warehouse, gold Lakehouse or Warehouse per domain) but layer assignments are **not** confirmed by pipeline documentation in `knowledge/` yet (knowledge folders were empty before this document set).

### 7.3 Source systems visible from names (Inferred)

| Signal | Likely source |
|---|---|
| BuildPro / HBLive / SPLive | Azure SQL on `gbpsql01` via mirroring |
| Encompass | Azure SQL DB present; Fabric mirror not observed under DataSources |
| Salesforce* | Salesforce ingestion pipelines / lakehouse / warehouses |
| Zonda* | Zonda load notebooks and lakehouse |
| Dataverse `gbpdev` / `gbpprod` | Dataverse connectors / lakehouses |

---

## 8. Security and credentials (Confirmed practices + gaps)

**Confirmed:**

- Key Vault `gb-fabric-keyvault` exists with RBAC authorization enabled
- Foundation Cursor rule: never hardcode credentials; prefer Key Vault and Workspace Identity
- Fabric export strips sensitivity labels and does not export data (fab warning observed)

**Gaps / follow-ups (not yet evidenced in knowledge docs):**

- Workspace identity assignments per workspace
- Key Vault secret inventory (intentionally not enumerated here)
- Private Link vs public access posture for Fabric itself
- SQL `publicNetworkAccess` is Enabled despite private endpoints existing (confirm intentional)

---

## 9. Knowledge tree

Prior art folders under `knowledge/` (created as empty shells before this documentation):

```
knowledge/
├── architecture/
├── decisions/
├── inventory/          <-- this document
├── lineage/
├── notebooks/
├── pipelines/
├── rebuild-plan/
├── reports/
├── runbooks/
├── security/
├── semantic-models/
└── workspace-map/
```

Related docs written with this pass:

- `knowledge/inventory/environment.md` (this file)
- `knowledge/workspace-map/workspaces.md`
- `knowledge/architecture/overview.md`

---

## 10. Tooling and automation (Confirmed)

| Tool | Purpose |
|---|---|
| `fab` | Source of truth for live Fabric artifacts; export / ls / auth |
| `az` | Azure subscription, RGs, capacity, SQL, network, Key Vault |
| `automation/export-fabric-live.sh` | Timestamped workspace definition snapshots |
| Preferred stack (project rule) | Fabric Notebooks (PySpark), Delta MERGE, `fab`, `az`, PowerShell 7 |

Naming conventions (project rule; target state, not yet enforced on all live names):

- Workspaces: `gbp-<domain>-<env>`
- Pipelines: `pl_<domain>_<object>`
- Notebooks: `nb_<domain>_<object>`
- Semantic models: `sm_<domain>_<subject>`

**Observed live naming (Confirmed):** many artifacts use older patterns (`pp_load_stg_to_*`, `EDW_*`, domain workspaces like `Finance-Dev` rather than `gbp-finance-dev`). Treat rule names as the target convention for new work.

---

## 11. Open follow-ups

1. Re-run `automation/export-fabric-live.sh` to completion and point `latest` at a full snapshot.
2. Inventory pipelines/notebooks into `knowledge/pipelines` and `knowledge/notebooks` from a complete snapshot.
3. Confirm medallion ownership (which workspace owns bronze/silver/gold for each domain).
4. Document Key Vault usage patterns and workspace identities under `knowledge/security`.
5. Install PowerShell 7 if cross-platform scripts in the preferred stack are required on this Mac.
6. Decide whether live workspace names should migrate toward `gbp-<domain>-<env>`.

---

## 12. Evidence sources

| Source | When |
|---|---|
| `fab auth status`, `fab ls -l`, `fab ls <workspace>` | 2026-07-13 |
| `az account show`, `az group` / `az resource list`, capacity / Key Vault / SQL / VNet queries | 2026-07-13 |
| Local filesystem under `~/Documents/Projects/Foundation` | 2026-07-13 |
| Session history of partial export stop on 2026-07-09 | Confirmed by remaining snapshot folders |
