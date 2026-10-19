# Architecture overview

**Documented:** 2026-07-13  
**Scope:** Green Brick Fabric platform as observed from Azure + Fabric CLI  
**Companion docs:** `knowledge/inventory/environment.md`, `knowledge/workspace-map/workspaces.md`

---

## Confirmed topology

```
Entra tenant e4a6f415-...
└── Subscription Production-Fabric (ef9cbd96-...)
    ├── rg-wus3-network
    │     └── VNet 10.3.0.0/20 + private DNS + DNS resolver + Fabric route table
    ├── rg-wus3-data
    │     └── SQL gbpsql01 (BuildPro, HBLive, SPLive, Encompass) + private endpoints
    └── rg-gbpartner-fabric
          ├── Capacity gbpwus3fabric01 (F32, West US 3)
          ├── Key Vault gb-fabric-keyvault (RBAC)
          ├── NSG GBP-nsg-Fabric
          └── Storage gbpintegrationfiles (southcentralus)
                │
                ▼
          Fabric workspaces on gbpwus3fabric01
                ├── DataSources          (SQL mirrors)
                ├── GBP-Enterprise[-Dev] (EDW + pipelines)
                ├── Finance[-Dev]        (reporting)
                ├── Operations[-Dev]     (domain gold lakehouse)
                ├── Foundation Development / Foundation
                ├── Foundation Governance (RBAC / inventory; D17)
                ├── Audit-Dev            (leftover source; not deleted)
                └── Capacity Metrics / GitTest
```

---

## Logical data flow (Inferred from names)

```
Azure SQL (gbpsql01)
  BuildPro / HBLive / SPLive  --->  DataSources MirroredDatabases
Encompass (SQL only; no Fabric mirror observed)

Other sources (Salesforce, Zonda, Dataverse)
  --->  GBP-Enterprise[-Dev] lakehouses / dataflows / ingestion pipelines

Landing / staging lakehouses & warehouses
  --->  pp_load_stg_to_dim_* / pp_load_stg_to_fact_* pipelines
  --->  EDW_Silver.Warehouse
  --->  EDW_Gold.Warehouse (Enterprise)
  --->  EDW_Gold.Lakehouse (Operations)

Semantic models + reports
  --->  Finance[-Dev], Customer Satisfaction, Capacity Metrics, RTI samples
```

This flow is **inferred** from artifact names and workspace placement. Pipeline definition review under a complete `snapshots/latest` is required to confirm transform boundaries and schedules.

---

## Layer boundaries (target rule vs observed)

Foundation rule (target, decided 2026-07-15): layers are named **raw**, **stage**, and **analytics**. Medallion terms (bronze, silver, gold) are not used in new work; they appear below only where they are part of existing artifact names.

- Raw: Lakehouse
- Stage: Warehouse
- Analytics: Lakehouse or Warehouse per domain

Observed named stores (Confirmed) mapped to that pattern (Inferred assignment):

| Layer | Store | Workspace |
|---|---|---|
| Raw | `gbp_lakehouse`, source LH, mirrored DBs | Enterprise / DataSources |
| Stage | `EDW_Silver.Warehouse` (legacy name) | GBP-Enterprise[-Dev] |
| Analytics | `EDW_Gold.Warehouse` (legacy name) | GBP-Enterprise[-Dev] |
| Analytics (domain) | `EDW_Gold.Lakehouse` (legacy name) | Operations[-Dev] |

Staging lakehouses/warehouses for Dataflows exist in large numbers; treat them as implementation scaffolding unless lineage docs promote them into the formal layer map.

---

## Environment pairing

| Domain | Dev workspace | Prod workspace |
|---|---|---|
| Enterprise EDW | GBP-Enterprise-Dev | GBP-Enterprise |
| Finance | Finance-Dev | Finance |
| Operations | Operations-Dev | Operations |
| Audit / governance | Audit-Dev (leftover) | Foundation Governance (D17, single workspace) |
| Shared sources | DataSources | (single shared) |

---

## Design constraints for new work

1. Confirm target workspace before generating artifacts.
2. Prefer Key Vault (`gb-fabric-keyvault`) and Workspace Identity; never hardcode credentials.
3. Preserve raw / stage / analytics boundaries; do not write analytics transforms into raw lakehouses.
4. Prefer new names: `gbp-<domain>-<env>`, `pl_*`, `nb_*`, `sm_*` (existing estate still uses older `pp_*` / domain display names).
5. Table and view naming: no `dim_`, `fact_`, or `vw_` prefixes; descriptive names with shape markers (`obt`, `sum`, `det`, `hist`, `map`) and period suffixes last (`sales_sum_weekly`). Full standard in `knowledge/rebuild-plan/rearchitecture.md` section 2.
6. Use `fab` as the live source of truth; refresh `snapshots/latest` after meaningful changes.

---

## Gaps to close

- Full definition snapshot (`latest` currently empty shells)
- Pipeline and notebook catalogs under `knowledge/pipelines` and `knowledge/notebooks`
- Explicit lineage diagrams once definitions are exported
- Security runbook for Key Vault secrets and workspace identities
- Decision records for naming migration and Encompass mirroring

---

## Re-architecture

The comprehensive target-state proposal and phased migration plan live in
`knowledge/rebuild-plan/rearchitecture.md`, with open decisions tracked in
`knowledge/decisions/README.md`.
