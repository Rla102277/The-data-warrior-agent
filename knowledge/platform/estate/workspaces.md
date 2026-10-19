# Fabric workspace map

**Captured:** 2026-10-16  
**Method:** `fab ls` (Confirmed)  
**Operator:** `rarchambault@greenbrickpartners.com`  
**Raw dump:** [`../inventory/fab-workspace-items-2026-10-16.txt`](../inventory/fab-workspace-items-2026-10-16.txt)

## Tenant workspaces observed

| Workspace | Type | Notes |
|---|---|---|
| Foundation Development | Rebuild / proof | Primary engineering target (D12) |
| Foundation | Prod twin | Deployment pipeline pair with FD |
| Foundation Governance | Governance only | Not a Dev/Prod pair (D17) |
| GBP-Enterprise | Legacy | Large pipeline fleet |
| GBP-Enterprise-Dev | Legacy pair | Present |
| Operations | Domain presentation | Thin; EDW_Gold |
| Operations-Dev | Domain pair | Thin |
| Finance | Domain presentation | Exec dashboards |
| Finance-Dev | Domain pair | Present |
| DataSources | Source mirrors | BuildPro, HBLive, SPLive mirrored DBs |
| GitTest | Tooling | Ignore for product work |
| Microsoft Fabric Capacity Metrics (+ dated copy) | Capacity | Ops tooling |
| My workspace | Personal | Skip |

## Foundation Development — item classes (Confirmed)

| Class | Examples |
|---|---|
| Lakehouses | HBLive, SPLive, BuildPro, dataverse_gbpdev, lake_house_analytics, lake_house_salesforce, lake_house_zonda, lake_house_web, lake_house_buildermetrix, lake_house_pipeline, lake_house_scratch |
| Warehouses | warehouse_stage, warehouse_salesforce |
| Pipelines | pipeline_stage_orchestrator, pipeline_stage_wave_runner, pipeline_stage_history_load, pipeline_salesforce_*, pipeline_zonda_load, pipeline_web_scrape*, pipeline_operations_analytics_refresh, pipeline_harvest_enterprise, pipeline_mirror_compare, pipeline_sql_runner, pipeline_audit_cleanup |
| Notebooks | notebook_zonda_*, notebook_web_*, notebook_pipeline_*, notebook_operations_* |
| Semantic models / reports | finance executive/weekly; operations sales, lot events, customer survey, market intelligence, web listings/coverage/change, competitor analysis; title booking |
| Activators | activator_*_failure reflexes; one dated unnamed Activator |
| Variable library | variable_library_operations |

## Foundation Governance (Confirmed)

- `lake_house_governance`
- Notebooks: auditor capture/guide, object dependency, RBAC audit/drift/policy (lakehouse/warehouse + semantic models)

## DataSources (Confirmed)

Mirrored databases + SQL endpoints: BuildPro, HBLive, SPLive.

## GBP-Enterprise (Confirmed summary)

- ~175 items; ~93 DataPipelines
- EDW_Silver / EDW_Gold warehouses + semantic models
- dataverse_gbpdev and dataverse_gbpprod lakehouses
- Wrapper-style load pipelines `pp_load_stg_to_dim_*` (audit / full / no_audit variants)
- Salesforce ingestion pipelines (prod/UAT/bkp)
- Zonda notebooks with legacy `nb_` names

## Operations / Finance (Confirmed)

- Operations: EDW_Gold lakehouse, CustSat reports/models, variable library
- Finance: Executive Dashboard + Executive Unit Dashboard (report + semantic model pairs)
