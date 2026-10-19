# Utility and ancillary pipelines

**Documented:** 2026-07-15  
**Workspace:** GBP-Enterprise (legacy catalog below); Foundation Development additions at bottom.

## Foundation Development utilities (2026-08-12)

Built via [`automation/fix_pipeline_gaps.py`](../../automation/fix_pipeline_gaps.py). Schedules OFF.

| Pipeline | FD ID | Replaces | Notes |
|---|---|---|---|
| `pipeline_audit_cleanup` | `a6658e72-d20d-4e13-b83f-9036bd9bfac8` | `pp_audit_cleanup` | Single proc: `control.sp_audit_cleanup` |
| `pipeline_stage_history_load` | `7167c482-8ca8-469a-9a3a-2a3c7bfd1903` | `pp_fact_hist_scheduled` + 3 hist wrappers | Tue / last-day-of-month criteria; 3 hist procs in parallel |
| `pipeline_mirror_compare` | `c39694e4-ed1e-4a27-90ee-671d0e93ebad` | `pp_compare_azure_vs_mirrored_db` | Adapted from Enterprise; verify mirror SQL connections |
| `pipeline_web_scrape` | `01a78eb2-c176-4604-88bb-974700cb991d` | (new, D19) | Reads `control.web_scrape_source`; files in `lake_house_web`; typed tables in `warehouse_stage.raw` (never dbo); schedule OFF |

See also [`gap-register.md`](gap-register.md).

---

## `pp_audit_cleanup`
- ID: `b1f9cebd-7397-4634-b974-7a291f70f5a9`
- Top flow: SqlServerStoredProcedure:sp_call_audit_cleanup
- Activity types: `{'SqlServerStoredProcedure': 1}`
- Schedule: ON Daily @00:00 (Central Standard Time; end 2025-12-31)
- Runs: 0 tot / 0 ok / 0 fail
- Artifacts: `EDW_Silver.Warehouse`

## `pp_compare_azure_vs_mirrored_db`
- ID: `e034c1e2-bd47-4562-9e74-db39743fec96`
- Top flow: Lookup:Get Load Date -> Script:Truncate Column-Row Validation Table -> SetVariable:Set created_date -> Copy:Target DB Column Validation -> Copy:HBLive Source DB Column Validation -> Copy:SPLive Source DB Column Validation -> Copy:BuildPro Source DB Column Validation -> Copy:Target DB Row Validation ...
- Activity types: `{'Lookup': 1, 'Script': 3, 'SetVariable': 1, 'Copy': 8, 'SqlServerStoredProcedure': 1, 'IfCondition': 2, 'Office365Outlook': 2}`
- Schedule: ON Daily @06:30 (Eastern Standard Time; end 2025-12-31)
- Runs: 0 tot / 0 ok / 0 fail
- Connections: `GBP-Enterprise;HBLive;GB Azure SQL Authentication`, `gbpsql01.database.windows.net;BuildPro;GB Azure SQL Authentication`, `gbpsql01.database.windows.net;SPLive;GB Azure SQL Authentication`, `gbpsql01.database.windows.net;HBLive;GB Azure SQL Authentication`
- Artifacts: `EDW_Silver.Warehouse`

## `pp_delete_blocked_logs`
- ID: `29b8a417-0bb2-4f19-8972-00e0a24487cb`
- Top flow: Script:delete_blocked_log
- Activity types: `{'Script': 1}`
- Schedule: ON Cron every 120m (India Standard Time; end 2027-03-26)
- Runs: 369 tot / 369 ok / 0 fail
- Artifacts: `EDW_Silver.Warehouse`

## `pp_fact_hist_scheduled`
- ID: `21040099-0634-44a1-a532-c21927b49c3c`
- Top flow: IfCondition:run_criteria
- Activity types: `{'IfCondition': 1, 'InvokePipeline': 3}`
- Schedule: ON Daily @00:00 (Central Standard Time; end 2025-12-31)
- Runs: 0 tot / 0 ok / 0 fail
- Connections: `gbp-data-pipeline`
- Invokes:
  - `fact_lot_financials_hist` -> `pp_load_fact_lot_financials_to_fact_lot_financials_hist`
  - `fact_sgm_assumptions_hist` -> `pp_load_fact_sgm_assumptions_to_fact_sgm_assumptions_hist`
  - `fact_lot_sgm_hist` -> `pp_load_fact_lot_sgm_to_fact_lot_sgm_hist`

## `pp_load_view_to_csv`
- ID: `707d2933-5bad-46f6-8d27-a9fea2aa2ca7`
- Top flow: Lookup:lkp_get_ounit_codes -> ForEach:foreach_ounit_codes -> Copy:NSE_WorkOrder_Import_to_csv
- Activity types: `{'Lookup': 1, 'ForEach': 1, 'Copy': 2}`
- Schedule: none
- Runs: 326 tot / 326 ok / 0 fail
- Connections: `ADLS kradhakrishnan`
- Artifacts: `Salesforce_WH.Warehouse`

## `pp_load_zonda_to_fabric`
- ID: `ec029d90-9d22-4b2d-8ea3-0a33e129b7a4`
- Top flow: TridentNotebook:get_credentials -> TridentNotebook:load_community -> TridentNotebook:load_plans -> TridentNotebook:load_lots
- Activity types: `{'TridentNotebook': 4}`
- Schedule: none
- Runs: 0 tot / 0 ok / 0 fail

## `pp_temp_schema_discovery`
- ID: `d30a42ee-ce1a-4176-a46c-db433ea555b8`
- Top flow: Copy:Copy data1
- Activity types: `{'Copy': 1}`
- Schedule: none
- Runs: 2 tot / 2 ok / 0 fail
- Connections: `Salesforce_Prod`
- Artifacts: `Salesforce_WH.Warehouse`

## `pp_load_fact_lot_financials_to_fact_lot_financials_hist`
- ID: `5535a19d-0e92-4bea-85f8-30f512a197ff`
- Top flow: Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp
- Activity types: `{'Script': 2, 'Lookup': 1, 'SetVariable': 3, 'SqlServerStoredProcedure': 1}`
- Schedule: none
- Runs: 0 tot / 0 ok / 0 fail
- Artifacts: `EDW_Silver.Warehouse`

## `pp_load_fact_lot_sgm_to_fact_lot_sgm_hist`
- ID: `2b065f38-d2d5-40d7-9c18-6ef8c62c7458`
- Top flow: Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp
- Activity types: `{'Script': 2, 'Lookup': 1, 'SetVariable': 3, 'SqlServerStoredProcedure': 1}`
- Schedule: none
- Runs: 0 tot / 0 ok / 0 fail
- Artifacts: `EDW_Silver.Warehouse`

## `pp_load_fact_sgm_assumptions_to_fact_sgm_assumptions_hist`
- ID: `e5ea70f0-9daa-4d22-b466-d1927b85ce76`
- Top flow: Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SetVariable:set_failed_activity_to_sp -> SqlServerStoredProcedure:sp_call_increamental_load
- Activity types: `{'Script': 2, 'Lookup': 1, 'SetVariable': 3, 'SqlServerStoredProcedure': 1}`
- Schedule: none
- Runs: 0 tot / 0 ok / 0 fail
- Artifacts: `EDW_Silver.Warehouse`
