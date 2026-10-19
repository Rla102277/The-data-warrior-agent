# Fabric workspace map

**Documented:** 2026-07-13  
**Source:** live `fab ls` / `fab ls -l`  
**Capacity:** `gbpwus3fabric01` (F32, West US 3) for all `*.Workspace` entries below  
**Personal workspace excluded** from export automation

---

## Quick map

```
Production-Fabric subscription
└── Capacity gbpwus3fabric01 (West US 3)
    ├── Foundation Governance     (9)   auditor pack + RBAC / inventory (D17)
    ├── Audit-Dev                 (9)   leftover source; not deleted
    ├── Foundation Development          Foundation rebuild (dev)
    ├── Foundation                      Foundation rebuild (prod twin)
    ├── DataSources               (6)   SQL mirrors
    ├── Finance-Dev              (25)   finance reporting (dev)
    ├── Finance                   (4)   finance reporting (prod)
    ├── GBP-Enterprise-Dev      (167)   EDW + orchestration (dev)
    ├── GBP-Enterprise          (171)   EDW + orchestration (prod)
    ├── GitTest                   (1)   git/pipeline test
    ├── Microsoft Fabric Capacity Metrics (2)
    ├── Operations-Dev            (3)   ops gold (dev)
    └── Operations               (12)   ops gold + RTI sample (prod)
```

Dev / Prod pairs (Confirmed by naming): Finance, GBP-Enterprise, Operations, Foundation Development / Foundation. Audit exists as Dev only. Governance is a single workspace (D17), not a pair.

---

## Foundation Governance.Workspace

**ID:** `c9fde10b-f6ed-4a45-a05b-9d41eb782ed8`  
**Created:** 2026-08-20  
**Items:** 9 (Lakehouse + SQLEndpoint + 7 notebooks)  
**Doc:** [`knowledge/operations/governance-workspace.md`](../operations/governance-workspace.md)

Single governance workspace for the Foundation estate. Auditor start here:
`notebook_governance_auditor_guide`, then `notebook_governance_auditor_capture`
(read-only snapshot into `lake_house_governance`). RBAC / inventory notebooks
copied from Audit-Dev. No Finance report. Schedules off.

---

## Audit-Dev.Workspace

**ID:** `39854263-5bae-4eb2-a9b6-6ba274d7476d`  
**Items:** 9

| Type | Count |
|---|---|
| Notebook | 5 |
| Lakehouse | 1 |
| SQLEndpoint | 1 |
| Report | 1 |
| SemanticModel | 1 |

Items:

- Audit_Lakehouse.Lakehouse (+ SQLEndpoint)
- Executive Unit Dashboard.Report / .SemanticModel
- Object Dependency Check.Notebook
- RBAC Audit & Drift Detection.Notebook
- RBAC Audit Maintenance.Notebook
- RBAC Policy Generation & Application (Lakehouse + Warehouse only).Notebook
- RBAC Policy Generation & Application (Semantic Models + Power BI).Notebook

---

## DataSources.Workspace

**ID:** `70ffb171-dc73-4b17-b7b4-e8dea16b925a`  
**Items:** 6

| Type | Count |
|---|---|
| MirroredDatabase | 3 |
| SQLEndpoint | 3 |

Items:

- BuildPro.MirroredDatabase
- HBLive.MirroredDatabase
- SPLive.MirroredDatabase

Aligned Azure SQL databases on `gbpsql01` (Confirmed): BuildPro, HBLive, SPLive. Encompass exists on SQL but is not mirrored here.

---

## Finance-Dev.Workspace

**ID:** `d9293f73-accc-45cb-bb1c-9fab65256758`  
**Items:** 25

| Type | Count |
|---|---|
| SemanticModel | 11 |
| Report | 10 |
| PaginatedReport | 3 |
| Notebook | 1 |

Notable items: weekly sales / unit report variants (Optimized, Light, Hybrid), CustSatReport, Executive Unit Dashboard, Report Usage Metrics, best practice analyzer notebook, paginated Fast Weekly Sales / Unit reports.

---

## Finance.Workspace

**ID:** `9b62026a-4675-4ddb-a0ad-2177f597f114`  
**Items:** 4

- Executive Dashboard.Report / .SemanticModel
- Executive Unit Dashboard.Report / .SemanticModel

---

## GBP-Enterprise-Dev.Workspace

**ID:** `bf1c626e-e497-4fa3-b5ff-510be3158541`  
**Items:** 167

| Type | Count |
|---|---|
| DataPipeline | 90 |
| Notebook | 16 |
| Lakehouse | 13 |
| SQLEndpoint | 13 |
| SemanticModel | 13 |
| Warehouse | 10 |
| Reflex | 5 |
| Report | 2 |
| Dataflow | 2 |
| Eventstream | 1 |
| Eventhouse | 1 |
| KQLDatabase | 1 |

### Lakehouses / warehouses (Confirmed)

Lakehouses: BuildPro, HBLive, SPLive, Salesforce, Zonda, gbp_lakehouse, dataverse_gbpdev, dataverse_gbpprod, plus Dataflows staging lakehouses.

Warehouses: EDW_Silver, EDW_Gold, DataflowsStagingWarehouse, Salesforce_WH, Salesforce_WH_UAT, WebsiteData, plus staging warehouses.

### Orchestration signals (Confirmed names)

- Pipelines: large `pp_load_stg_to_dim_*` / `pp_load_stg_to_fact_*` family (audit / full / no_audit variants), Salesforce ingestion (`pp_fabric_salesforce_ingestion_*`), hist loaders, orchestration pipelines
- Reflexes: `act_pp_orchestration_*`, `act_pp_salesforce_orchestrator`, job failure / Zonda alerts
- Realtime: `capacity_overview_eventstream`, `FabricCapacityEventhouse`

---

## GBP-Enterprise.Workspace

**ID:** `855ce463-047f-4fd0-9e3e-5ed6faccee5e`  
**Items:** 171

Near-parallel inventory to GBP-Enterprise-Dev (same pipeline / notebook / reflex pattern). Slightly higher Lakehouse / Warehouse / SemanticModel counts (14 / 11 / 14).

Treat as the production twin of GBP-Enterprise-Dev until lineage docs prove otherwise (Inferred relationship from naming and near-identical item sets).

---

## GitTest.Workspace

**ID:** `520d9dad-b35b-4c5e-82c2-1764a234e454`  
**Items:** 1

- Pipeline_1.DataPipeline

---

## Microsoft Fabric Capacity Metrics.Workspace

**ID:** `d376af32-9a7f-401e-b836-cabf63009545`  
**Items:** 2

- Fabric Capacity Metrics.Report
- Fabric Capacity Metrics.SemanticModel

---

## Operations-Dev.Workspace

**ID:** `41415a12-1442-4a58-ae6d-686109fd7108`  
**Items:** 3

- EDW_Gold.Lakehouse (+ SQLEndpoint)
- Operations-Variable-Library.VariableLibrary

---

## Operations.Workspace

**ID:** `6c8f8e5a-ccac-40c0-ae3e-2abb84309f35`  
**Items:** 12

- EDW_Gold.Lakehouse (+ SQLEndpoint)
- Operations-Variable-Library.VariableLibrary
- CustomerSatisfactionSurveyResults_Prod.Report / .SemanticModel
- CustomerSatisfactionSurveyResults_v2.Report (2026-08-25; same SM; Prod not replaced)
- RTISample.* (Eventhouse, Eventstream, KQLDashboard, KQLDatabase, KQLQueryset, Report, SemanticModel)

---

## My workspace.Personal

**ID:** `5c7956e6-4043-4669-9fd8-4cff84eb84d0`  
**Capacity:** none  
Skipped by `export-fabric-live.sh`.

---

## Snapshot coverage note

Local partial snapshot `snapshots/snapshot_2026-07-09_15-39` contains definition exports for Audit-Dev, DataSources, Finance, Finance-Dev, and a large portion of GBP-Enterprise-Dev. Remaining workspaces were not exported before the run was stopped. `snapshots/latest` still points at empty shells under `snapshot_2026-07-09_15-34`.
