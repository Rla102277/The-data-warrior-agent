# D13 naming and data model standard

**Decision:** D13 (2026-08-10), extended by D0 layer vocabulary  
**Applies to:** All new work in **Foundation Development** and **Foundation** prod twin

## Workspace and product names

| Item | Correct name | Do not use |
|---|---|---|
| Dev workspace | **Foundation Development** | bare `foundation` as workspace name |
| Prod workspace | **Foundation** | bare `foundation` as workspace name |
| dbt / product label | **`foundation`** | N/A |
| Governance workspace | **Foundation Governance** | second audit workspace; Finance reports inside governance |

## Fabric artifact naming (spell tool names)

| Artifact | Pattern | Example | Banned acronyms |
|---|---|---|---|
| Pipeline | `pipeline_<domain>_<object>` | `pipeline_stage_orchestrator` | `pl_*`, `pp_*` (new work) |
| Lakehouse | `lake_house_<subject>` | `lake_house_analytics` | `lh_*` |
| Warehouse | `warehouse_<subject>` | `warehouse_stage` | `wh_*` |
| Notebook | `notebook_<domain>_<object>` | `notebook_web_scrape` | `nb_*` |
| Semantic model | `semantic_model_<domain>_<subject>` | `semantic_model_title_booking` | `sm_*` |
| Variable library | `variable_library_<subject>` | `variable_library_operations` | |
| Data agent | `data_agent_<domain>_<subject>` | `data_agent_operations_customer_survey` | `da_*`, `ai_*` |

## Schema and layer rules

| Schema / layer | Purpose |
|---|---|
| `raw` | Landed files and typed landing tables |
| `stage` | Orchestration shell (often empty tables; shortcuts feed transform) |
| `control` | Config, audit, registry |
| `transform` | Conformed entities and facts loaded by procs |
| `analytics` | dbt consumption views |

**Never place new business objects in `dbo`.**

Banned in new Foundation objects: **`EDW_*`**, **`dim_`**, **`fact_`**, **`vw_`**.

Medallion terms (bronze/silver/gold) are not used in new names.

## Table and view naming pattern

```
<subject>[_<qualifier>]_<shape>[_<period>]
```

### Shape markers (suffix, lowercase)

| Marker | Meaning | When to use | Example |
|---|---|---|---|
| *(none)* | Reference entity (current row) | Shared dimensions, keys | `company`, `lot`, `sale`, `project` |
| **`obt`** | One Big Table | Report-ready denormalized grain | `title_booking_obt`, `sale_obt`, `lot_events_obt` |
| **`det`** | Detail / line / transaction | Repeating lines, GL detail | `general_ledger_det`, `title_communities_det` |
| **`sum`** | Summary / aggregate | Pre-aggregated metrics | `sales_sum_weekly`, `unit_sum_weekly` |
| **`hist`** | History / snapshot / budget history | Point-in-time or versioned snapshots | `unit_budget_hist` |
| **`map`** | Bridge / crosswalk | Many-to-many or code maps | `sales_gross_margin_map` |

### Period suffix

When grain is time-bound, period goes **last**: `sales_sum_weekly`, `sales_sum_monthly` (not `weekly_sales_sum`).

### Active rows

**Do not publish `*_active` twins** to the analytics lakehouse. Filter `is_active = 'Y'` in the entity model or use a warehouse-only wrapper tagged `unpublished` in dbt.

## Stored procedures

Pattern: `transform.sp_load_<target_name>`

Examples: `sp_load_company`, `sp_load_sale`, `sp_load_general_ledger_det`

Load behavior driven by `control.stage_load_config` (`default_load_type`, `run_wave`, `run_group`).

## dbt project contract

| Setting | Value |
|---|---|
| Project name | `foundation` |
| Analytics views | `warehouse_stage.analytics.*` |
| Materialized tables | `lake_house_analytics.operations.*` (shared store; domain via refresh config) |
| Model classes | `entity` (thin transform passthrough) vs `report` (joins/reshape for BI) |

Deploy: `dbt/deploy_via_sql_runner.sh` when ODBC unavailable.

## OBT vs DET vs SUM (vendor guidance)

| Shape | Grain question | Typical sources | Consumer |
|---|---|---|---|
| **OBT** | One row per business report row? | Join entity + facts + attributes | Semantic models, operational reports |
| **DET** | One row per transaction/line? | Fact tables, GL lines, community rows | Drill-through, exports, staging for OBT |
| **SUM** | One row per bucket (week, month, OU)? | Aggregations over events or sales | Executive dashboards, planning feeds |
| **HIST** | One row per version or budget snapshot? | SCD2 loads, manual budget harvest | Planning, variance analysis |
| **MAP** | One row per mapping rule? | Dataverse, manual crosswalks | Finance SGM, security mapping |

### Published examples (Confirmed in FD)

| Model | Shape | Grain / notes |
|---|---|---|
| `title_booking_obt` | OBT | `selection_id`; Title department |
| `title_communities_det` | DET | Community map; derived from booking OBT |
| `sale_obt` | OBT | Current sale row + attributes |
| `lot_events_obt` | OBT | Lot lifecycle events |
| `customer_survey_obt` | OBT | `response_id` |
| `general_ledger_det` | DET | GL lines |
| `lot_financials_det` | DET | Lot financial lines |
| `sales_sum_weekly` | SUM | OU + week_start + event_type |
| `unit_sum_weekly` | SUM | OU + week_start |
| `sales_sum_monthly` | SUM | OU + month_start; **budget grain** |
| `unit_budget_hist` | HIST | Unit budget snapshots |
| `sales_gross_margin_map` | MAP | SGM crosswalk |

Full map: [`../analytics/gold-to-dbt-map.md`](../analytics/gold-to-dbt-map.md) (37 legacy Gold views + FD-only models).

## What vendors must not deliver

- New `dim_company`, `fact_general_ledger`, `vw_rep_*` in Foundation  
- Per-domain lakehouses without D15 exception  
- Analytics transforms written only in Power Query without dbt ownership  
- Tool acronyms in new artifact names (`pl_`, `sm_`, ...)

## Rename authority

Complete legacy → D13 map: [`../rebuild-plan/rename-map.md`](../rebuild-plan/rename-map.md)  
Parity proof: [`../rebuild-plan/edw-d13-eval.md`](../rebuild-plan/edw-d13-eval.md) (102/104 objects rebuilt in FD)
