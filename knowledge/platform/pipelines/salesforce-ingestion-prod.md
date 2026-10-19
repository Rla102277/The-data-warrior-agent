# Salesforce ingestion pipelines (prod)

**Documented:** 2026-07-15  
**Workspace:** GBP-Enterprise (`855ce463-047f-4fd0-9e3e-5ed6faccee5e`)  
**Evidence:** live `fab` definitions + SQL against `Salesforce_WH.metadata.Ingestion_Config` and `logging.Pipeline_Table_Load_Log`

There is no artifact literally named `PP_SPALESFORCE_INGESTION_PROD`. The prod Salesforce sync is this pair plus an orchestrator.

---

## Identity map

| Role | Display name | ID |
|---|---|---|
| Outbound (Fabric → Salesforce) | `pp_fabric_salesforce_ingestion_prod` | `e12fc780-d609-4361-8f07-24c3c3e71e48` |
| Inbound (Salesforce → Fabric) | `pp_salesforce_fabric_ingestion_prod` | `22a02d16-b512-4f89-91f1-89b046c86028` |
| Orchestrator | `pp_salesforce_orchestrator_prod` | `2ff24d32-6afa-43c0-842c-55eef794cd77` |
| Views to CSV (3rd step) | `pp_load_view_to_csv` | `707d2933-5bad-46f6-8d27-a9fea2aa2ca7` |

Config `Pipeline_Name` values in the warehouse use the non-`_prod` base names (`pp_salesforce_fabric_ingestion`, `pp_fabric_salesforce_ingestion`).

---

## Shared dependencies

| Dependency | Value |
|---|---|
| Connection | `Salesforce_Prod` (`207e8644-adf2-4e53-97d7-b14f9679bce4`) |
| Salesforce org URL | `https://greenbrick.my.salesforce.com/` |
| Warehouse | `Salesforce_WH` (`adfe4a3b-9adc-4661-a8b7-f4ef7fcf7059`) |
| SQL endpoint | `cx2knzbh2yrejngvheequwseqy-mpsfzbl7atie7hr6l3lpvtholy.datawarehouse.fabric.microsoft.com` |
| Config table | `metadata.Ingestion_Config` |
| Load log | `logging.Pipeline_Table_Load_Log` |
| Join source (outbound Vendors) | `HBLive.rems.province` (Confirmed in Join_Definition) |

---

## Orchestration and schedule

`pp_salesforce_orchestrator_prod` (enabled Daily, Central):

1. `fabric_to_salesforce` → outbound pipeline  
2. `salesforce_to_fabric` → inbound pipeline (after success)  
3. `load_views_to_csv` → `pp_load_view_to_csv`

Times: **10:00, 13:00, 16:00** Central, `2026-06-25` through `2027-06-25`.

Outbound pipeline also has its own Cron every 10 minutes, but **`enabled: false`**. Child runs appear as Manual because the orchestrator invokes them.

---

## Config inventory (Confirmed 2026-07-15)

**17 active rows:** 10 Inbound Full, 5 Outbound Update, 2 Outbound Insert. All `IsActive=Y`.

### Inbound (`Pipeline_Type=Inbound`) → truncate + full load into `dbo`

| Order | Salesforce object | Warehouse table | PK | Watermark |
|---|---|---|---|---|
| 8 | Subdivision__c | dbo.Subdivision__c | Id | LastModifiedDate |
| 8 | Community__c | dbo.Community__c | Id | LastModifiedDate |
| 8 | Account | dbo.Account | Id | LastModifiedDate |
| 8 | AccountBrand | dbo.AccountBrand | Id | LastModifiedDate |
| 8 | Back_Charge__c | dbo.Back_Charge__c | Id | LastModifiedDate |
| 8 | Lot__c | dbo.Lot__c | Id | LastModifiedDate |
| 8 | User | dbo.User__c | Id | LastModifiedDate |
| 8 | Vendor_Lot_Relationship__c | dbo.Vendor_Lot_Relationship__c | Id | LastModifiedDate |
| 8 | WorkOrder | dbo.WorkOrder | Id | LastModifiedDate |
| 8 | WorkOrderLineItem | dbo.WorkOrderLineItem | Id | LastModifiedDate |

Note: SF object `User` lands as warehouse table `User__c`.

### Outbound (`Pipeline_Type=Outbound`) → upsert into Salesforce

| Order | Load | WH source (dbo view/table) | Salesforce target | External / PK field |
|---|---|---|---|---|
| 1 | Update | Lots | Lot__c | Newstar_ID__c |
| 2 | Update | Vendors | Account | External_ID__c |
| 3 | Insert | Vendors | Account | External_ID__c |
| 4 | Update | Vendor_Lot | Vendor_Lot_Relationship__c | External_Id__c |
| 5 | Insert | Vendor_Lot | Vendor_Lot_Relationship__c | External_Id__c |
| 6 | Update | PO_WorkOrders | WorkOrder | Id |
| 7 | Update | PO_BackCharges | Back_Charge__c | Id |

Vendors join: `LEFT OUTER JOIN HBLive.rems.province ON HBLive.rems.province.provcode=dbo.Vendors.state`.

---

## Latest healthy run snapshot (Confirmed load log)

Around **2026-07-15 16:50–17:07 UTC**:

**Outbound examples:** Lot__c update 36111 read / 36046 written; Account update 3/3; Vendor_Lot insert 258/258; WorkOrder update 57/33.

**Inbound examples:** Vendor_Lot_Relationship__c 1,087,515 rows; WorkOrderLineItem 324,883; WorkOrder 237,674; Lot__c 38,338; Account 21,066.

---

## Failure pattern (Confirmed)

June 16 2026 outbound failures repeatedly logged:

`Failed to resolve connection '207e8644-...' ... ErrorCode: 'DMTS_EntityNotFoundOrUnauthorized'`

That is a Salesforce connection resolution / authorization problem on `Salesforce_Prod`, not a table-mapping bug. Recent July runs for both directions are succeeding.

---

## Related siblings (same workspace)

- `pp_fabric_salesforce_ingestion_UAT` / `_bkp1`
- `pp_salesforce_fabric_ingestion_UAT` / `_test` / `_bkp1` / (non-suffixed)
- Reflex: `act_pp_salesforce_orchestrator`
- Lakehouse: `Salesforce.Lakehouse`
- Warehouses: `Salesforce_WH`, `Salesforce_WH_UAT`

Dev workspace GBP-Enterprise-Dev has same-named pipeline twins.
