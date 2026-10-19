# Scope: in scope and out of scope

**Use:** Attach to RFI/RFP/RFS as Section 2 (Scope). Adjust dates and dollar thresholds in procurement templates.

## Program objective

Rebuild and operate the Green Brick **Microsoft Fabric** analytics platform as **Foundation**, replacing the legacy GBP-Enterprise EDW packaging while preserving verified transform logic and expanding domain presentation under **D13** naming.

## In scope

### Platform and architecture

| Area | In scope |
|---|---|
| **Foundation Development** | Build, test, document additive artifacts |
| **Foundation prod twin** | Promote via deployment pipeline; rebind endpoints and semantic models |
| **Layer enforcement** | raw / control / transform / analytics; no new business objects in dbo |
| **D13 naming** | All new pipelines, lakehouses, warehouses, notebooks, semantic models, tables |
| **Stage loads** | Metadata-driven `pipeline_stage_orchestrator` + `control.stage_load_config` |
| **Analytics** | dbt project `foundation`; `pipeline_operations_analytics_refresh` |
| **Presentation** | Semantic models and reports under `analytics/<department>` |
| **Governance** | Foundation Governance read-only auditor pack (D17) |
| **Identity** | Key Vault secrets, workspace identity, replace personal connections |
| **Documentation** | Update `knowledge/` and runbooks for delivered work |

### Data domains (consumption layer)

| Domain | In scope status |
|---|---|
| **Shared entities** | company, division, OU, fiscal_period, lot, sale, job, ... (Confirmed) |
| **Operations** | lot_events, sale OBT, CustSat OBT, web scrape OBTs (Confirmed) |
| **Finance** | GL DET, SGM, unit_budget_hist, weekly/monthly sums (Confirmed) |
| **Title** | title_booking_obt, title_communities_det, title SM (Confirmed) |
| **Salesforce** | Inbound/outbound in Foundation stack (Confirmed; schedules gated) |
| **Zonda** | Load pipeline exists; blocked on Key Vault role (GAP-07) |
| **Web scrape** | Registry-driven scrape to raw; OBT materialization (Confirmed build) |
| **Mortgage** | Discovery, mirror design, Encompass transform/analytics **when Green Brick approves phase** |
| **Planning feeds** | Export or dataset contract from SUM/HIST tables to TM1 or successor (discovery) |

### Table shapes (in scope deliverables)

Vendors may be asked to design or extend:

- **OBT** report tables (`*_obt`)  
- **DET** line/detail tables (`*_det`)  
- **SUM** aggregates with period suffix (`*_sum_weekly`, `*_sum_monthly`)  
- **HIST** snapshots (`*_hist`)  
- **MAP** crosswalks (`*_map`)  
- Plain **entity** tables (no suffix) for conformed dimensions  

### Operations and quality

| Activity | In scope |
|---|---|
| Parity validation vs Enterprise (row counts, schema, proc equivalence) | Yes |
| Hydration runbooks and smoke tests | Yes |
| Pipeline health monitoring (`pipeline_health_obt` utilities view) | Yes |
| Failure alerting to `foundation_data_monitoring@greenbrickpartners.com` (D6 placeholder) | Yes |
| Purview catalog standup | Planned; in scope when prioritized |
| dbt tests and `_schema.yml` documentation | Yes for new models |

## Out of scope (unless explicitly added by change order)

### Production and legacy destruction (D12)

| Item | Out of scope default |
|---|---|
| Delete, retire, disable, or cut over **GBP-Enterprise**, **Finance**, **Operations** workspaces | **Out of scope** without explicit written instruction naming item + action |
| Remove legacy pipelines or reports in prod | **Out of scope** |
| Hard-delete Audit-Dev | **Out of scope** |

### Legacy replication

| Item | Out of scope |
|---|---|
| 1:1 clone of 90 Enterprise pipelines | Yes; replaced by metadata-driven design |
| Recreate `EDW_Silver` / `EDW_Gold` names in Foundation | Yes |
| 65 wrapper pipeline variants | Yes |
| `dim_*`, `fact_*`, `vw_*` new objects | Yes |
| Publish `*_active` twins to analytics lakehouse | Yes |

### Organization and HR

| Item | Out of scope |
|---|---|
| Company-wide HR job title standardization | Yes (example: BuildPro role work is access-package only) |
| Per-builder Fabric workspace proliferation | Yes; use `analytics/Builders/<OU>` folders instead |
| Paylocity / AD as master for security roles | Yes unless separate IAM project |

### Products and features

| Item | Out of scope unless named |
|---|---|
| Copilot Studio / M365 Copilot enterprise rollout | Yes (D16: Fabric data agent POC only) |
| Real-time RTI sample rebuild | Yes unless requested |
| Encompass mirror + mortgage analytics | **Deferred** (D3); out of scope for current phase |
| BuilderMetrix consumption models | **Deferred** (D18) |
| Weekly web scrape schedule in prod | **Deferred** until GAP-07 and adapter maturity |
| SQL MI cutover execution | Separate infrastructure project; docs only unless scoped |
| ITTOOLS BuildPro role cutover | Analysis only until stakeholders accept draft |

### Schedules

| Item | Default |
|---|---|
| Enable 15-minute prod schedules on Foundation | **Out of scope** until hydration sign-off |
| Enable Salesforce outbound to Prod | **Out of scope** (FD config disables outbound) |

## Assumptions

1. Green Brick provides Azure/Fabric contributor access to Foundation Development and read access to legacy workspaces for parity.  
2. Source systems (HBLive, SPLive, BuildPro) remain on `gbpsql01` or successor MI with equivalent connectivity.  
3. dbt-fabric remains the analytics deployment path.  
4. Single presentation lakehouse (`lake_house_analytics`) unless D15 is reopened.  
5. TM1 / Planning Analytics remains the planning system of record; Fabric feeds it; Fabric does not replace TM1 rules.

## Dependencies (Green Brick furnished)

| Dependency | Owner |
|---|---|
| Key Vault secret rotation and WI RBAC | Platform admin |
| Salesforce org credentials | CRM admin |
| Zonda API / Key Vault grant (GAP-07) | Platform admin |
| TM1 cube/process documentation | Finance |
| Encompass vendor API or SQL access decision | Mortgage IT |
| Title SM sign-off | Title ops + BI |
| Exchange DL for monitoring | IT |

## Acceptance criteria (typical engagement)

1. Delivered artifacts use D13 names and live in correct workspace folders.  
2. dbt models compile; analytics refresh succeeds for declared `p_domain`.  
3. Parity evidence documented for touched transform entities (where applicable).  
4. No undocumented prod changes.  
5. Knowledge doc updated in `knowledge/external-rfs/` or domain runbook as agreed.
