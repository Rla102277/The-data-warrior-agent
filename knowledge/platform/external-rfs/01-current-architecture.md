# Current architecture (legacy estate)

**Status:** Confirmed as live production today for ERP/EDW path  
**Scope:** Pre-Foundation cutover; legacy workspaces remain source of truth until an explicit cutover decision

## Platform topology

```
Entra tenant
└── Subscription Production-Fabric
    ├── rg-wus3-network (VNet, private DNS, Fabric route table)
    ├── rg-wus3-data
    │     └── SQL gbpsql01 (BuildPro, HBLive, SPLive, Encompass)
    └── rg-gbpartner-fabric
          ├── Capacity gbpwus3fabric01 (F32, West US 3)
          ├── Key Vault gb-fabric-keyvault
          └── Storage gbpintegrationfiles
                └── Fabric workspaces (see below)
```

Source: [`../architecture/overview.md`](../architecture/overview.md), [`../inventory/environment.md`](../inventory/environment.md)

## Workspace map (legacy + shared)

| Workspace | Role | Approx items |
|---|---|---|
| **DataSources** | SQL mirrors: BuildPro, HBLive, SPLive | 6 |
| **GBP-Enterprise** | Prod EDW, orchestration, 90 pipelines | 171 |
| **GBP-Enterprise-Dev** | Dev twin of Enterprise | 167 |
| **Finance / Finance-Dev** | Executive and weekly reporting | 4 / 25 |
| **Operations / Operations-Dev** | Ops gold lakehouse, CustSat reports | 12 / 3 |
| **Foundation Development** | Rebuild (parallel; not cutover) | growing |
| **Foundation** | Prod twin of FD (promoted subset) | parity target |
| **Foundation Governance** | Auditor pack, RBAC inventory (D17) | 9 |
| **Audit-Dev** | Leftover governance source | 9 |

## Legacy data flow (Confirmed names, Inferred boundaries)

```
Azure SQL gbpsql01
  BuildPro, HBLive, SPLive  --->  DataSources MirroredDatabase
  Encompass (SQL only; no Fabric mirror)

Salesforce, Zonda, Dataverse
  --->  GBP-Enterprise lakehouses / Salesforce_WH

EDW_Silver.Warehouse (legacy stage name)
  control.* audit tables
  dbo.dim_* / dbo.fact_*
  sp_load_dim_* / sp_load_fact_*

EDW_Gold.Warehouse (legacy analytics name)
  vw_* views (37), dim_*_active, rep_* tables

Finance / Operations workspaces
  Semantic models + reports bound to Gold views / lakehouses
```

## Legacy orchestration (Confirmed)

| Pipeline | Role |
|---|---|
| `pp_orchestration_without_pp_audit` | **Live** 15-minute EDW refresh; inline `sp_load_*` |
| `pp_orchestration_with_pp_audit` / `_full` | Dormant variants |
| ~65 `pp_load_stg_to_dim_*` / `pp_load_stg_to_fact_*` wrappers | **Dead** (orphan scan); never called by live orchestrator |
| Salesforce family | Inbound/outbound + orchestrator (separate cadence) |

Control plane: `EDW_Silver.control.audit_pipeline_control`, `audit_orchestrator_control`, `audit_sp_control`, `audit_step_control`.

## Legacy naming problems (why Foundation exists)

| Issue | Evidence |
|---|---|
| Layer collapse in one workspace | 13 lakehouses, 11 warehouses, 90 pipelines in GBP-Enterprise |
| Opaque table names | `dim_*`, `fact_*`, `vw_*` throughout EDW |
| Pipeline sprawl | 65 duplicate wrapper pipelines |
| No git / deployment pipeline on Enterprise | Manual dev/prod twins |
| Encompass not mirrored | On SQL only |
| Identity debt | Named SQL auth connections, public SQL access enabled |

## Source systems (Confirmed on SQL)

| System | Azure SQL DB | Fabric mirror | Primary use |
|---|---|---|---|
| NewStar ERP | HBLive | DataSources + Enterprise LH | Jobs, GL, fiscal periods, projects |
| NewStar Sales | SPLive | DataSources + Enterprise LH | Sales, buyers, selections (Title booking) |
| BuildPro | BuildPro | DataSources + Enterprise LH | Construction tasks, POs |
| Encompass | Encompass | **None** | Mortgage LOS (future) |
| Salesforce | SaaS | Salesforce_WH + lakehouse | CRM, lots, work orders |
| Zonda | Vendor feed | Zonda lakehouse | Market / community intelligence |
| Dataverse | gbpdev / gbpprod | dataverse_* lakehouses | SGM map, CustSat |

## Legacy consumers (Confirmed)

| Domain | Workspace | Typical binding |
|---|---|---|
| Finance | Finance, Finance-Dev | `EDW_Gold` views, weekly sales/unit reports |
| Operations | Operations | `EDW_Gold` lakehouse, CustSat |
| Title | Finance / Enterprise reports (legacy) | `vw_rep_title_booking`, `vw_rep_title_communities` |
| Audit | Audit-Dev | Executive Unit Dashboard |

Foundation replaces the **Gold view layer** with dbt + `lake_house_analytics`; legacy workspaces remain until cutover.
