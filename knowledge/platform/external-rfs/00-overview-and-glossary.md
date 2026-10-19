# Overview and glossary

## Program summary

Green Brick Partners is rebuilding its Microsoft Fabric analytics estate as **Foundation**: a domain-organized platform with enforced **raw / stage / analytics** layers, descriptive table naming (decision **D13**), **dbt**-owned consumption models, and a **Foundation Development** to **Foundation** deployment pipeline pair.

The legacy **GBP-Enterprise** workspace holds ~171 items including ~90 pipelines, most of which are dormant wrapper variants. Foundation Development replaces the live EDW path with a metadata-driven stage orchestrator, dbt analytics views, and a shared presentation lakehouse (`lake_house_analytics`).

**Product label:** `foundation` (dbt project name)  
**Fabric workspaces (pair):** `Foundation Development` (dev) and `Foundation` (prod twin)  
**Governance workspace (single):** `Foundation Governance` (D17; not a dev/prod pair)

## Glossary

| Term | Meaning |
|---|---|
| **Foundation (FD)** | `Foundation Development` workspace; additive rebuild and proof environment |
| **Foundation prod twin** | `Foundation` workspace promoted from FD via deployment pipeline |
| **GBP-Enterprise** | Legacy prod EDW workspace (90 pipelines, EDW_Silver / EDW_Gold) |
| **Raw** | Landed source data (mirrors, lakehouses, files). Schema `raw` where used |
| **Stage** | Conformed warehouse orchestration shell; in FD, `warehouse_stage` with schemas `control`, `transform`, `analytics` |
| **Transform** | Conformed entities loaded by `transform.sp_load_*` (former silver / EDW_Silver dbo) |
| **Analytics** | Consumption-ready dbt views and materialized lakehouse tables (former gold) |
| **D13** | Naming and layering standard (decision 2026-08-10). See doc 03 |
| **OBT** | One Big Table: denormalized report grain |
| **DET** | Detail / repeating line grain |
| **SUM** | Summary / aggregate; period suffix last (`sales_sum_weekly`) |
| **HIST** | History / snapshot / budget history |
| **MAP** | Bridge or crosswalk |
| **Entity** | Reference table with no shape suffix (`company`, `lot`, `sale`) |
| **TM1** | IBM Planning Analytics (legacy name TM1). Corporate planning / budgeting. **Not documented in Fabric repo; Green Brick to confirm process names and feeds** |
| **HBLive** | Azure SQL NewStar / ERP mirror (BuildPro companion; `HBLive.rems.*`) |
| **SPLive** | Azure SQL NewStar Sales mirror (`SPLive.dbo.*`; buyer/selection data) |
| **BuildPro** | Azure SQL construction ERP mirror |
| **Encompass** | Mortgage LOS on `gbpsql01`; **not mirrored to Fabric today** (open D3) |

## Solicitation types (quick distinction)

| Type | Typical use | This pack section |
|---|---|---|
| **RFI** | Market scan, architecture fit, integration options, pricing bands | Doc 06 |
| **RFP** | Fixed scope, milestones, SLAs, scored evaluation | Doc 07 |
| **RFS** | Time-and-materials or managed services against a capability list | Doc 08 |

## Non-negotiables for vendors

1. **No production destruction** without explicit Green Brick written approval per item (D12).  
2. **D13 naming** for all new Foundation Development artifacts.  
3. **No business objects in `dbo`** in new work; use layer schemas.  
4. **No `dim_`, `fact_`, `vw_`, `EDW_*`** in new Foundation objects.  
5. **Credentials:** Key Vault (`gb-fabric-keyvault`) and workspace identity; no hardcoded secrets.  
6. **Medallion terms** (bronze/silver/gold) are not used in new naming; use raw/stage/transform/analytics.
