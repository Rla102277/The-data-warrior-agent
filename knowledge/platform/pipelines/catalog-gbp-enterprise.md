# GBP-Enterprise pipeline catalog

**Documented:** 2026-07-15
**Workspace:** GBP-Enterprise (`855ce463-047f-4fd0-9e3e-5ed6faccee5e`)
**Count:** 90 pipelines (definitions exported: 90/90)
**Dev twin:** GBP-Enterprise-Dev has the same 90 display names

## Run health rollup
- Job history rows returned across pipelines: **2954** (Completed **2735**, Failed **213**)
- Note: `job run-list` returns a recent window per pipeline, not lifetime history

## Connections referenced (pipeline-level)
- `Salesforce_UAT (ShareableCloud)` — used by 6 pipeline(s)
- `gbp-data-pipeline (ShareableCloud)` — used by 6 pipeline(s)
- `GBP-Enterprise;HBLive;GB Azure SQL Authentication (ShareableCloud)` — used by 4 pipeline(s)
- `Salesforce_Prod (ShareableCloud)` — used by 3 pipeline(s)
- `gbpsql01.database.windows.net;BuildPro;GB Azure SQL Authentication (ShareableCloud)` — used by 1 pipeline(s)
- `gbpsql01.database.windows.net;SPLive;GB Azure SQL Authentication (ShareableCloud)` — used by 1 pipeline(s)
- `gbpsql01.database.windows.net;HBLive;GB Azure SQL Authentication (ShareableCloud)` — used by 1 pipeline(s)
- `ADLS kradhakrishnan (ShareableCloud)` — used by 1 pipeline(s)

## Artifact stores referenced in definitions
- `EDW_Silver.Warehouse` — referenced in 76 pipeline definition(s)
- `Salesforce_WH.Warehouse` — referenced in 10 pipeline definition(s)
- `Salesforce_WH_UAT.Warehouse` — referenced in 2 pipeline definition(s)

## Orchestration (6)

| Pipeline | ID | Top activities | Schedule | Recent runs | Connections |
|---|---|---|---|---|---|
| `pp_orchestration` | `17465852-a4ab-492e-b950-1050ed800d74` | InvokePipeline:dim_job_task -> InvokePipeline:dim_sale_transfer -> InvokePipeline:dim_job -> InvokePipeline:dim_sale -> InvokePipeline:dim_lot -> InvokePipeline:dim_major_minor -> InvokePipeline:fact_general_ledger -> InvokePipeline:dim_sgm_map ... | off Cron every 15m (Central Standard Time; end 2025-12-31) | 0 tot / 0 ok / 0 fail | gbp-data-pipeline |
| `pp_orchestration_full` | `22b96108-4107-427c-a468-80e8acbb1286` | IfCondition:If Condition1 -> Lookup:check_last_run_status -> Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time | none | 3 tot / 3 ok / 0 fail | gbp-data-pipeline |
| `pp_orchestration_with_pp_audit` | `e9201dd4-fccb-4e42-8884-64970fb5fa6e` | IfCondition:If Condition1 -> Lookup:check_last_run_status -> Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time | off Cron every 30m (Central Standard Time; end 2026-12-17) | 0 tot / 0 ok / 0 fail | gbp-data-pipeline |
| `pp_orchestration_without_pp_audit` | `9e2c73c1-f252-46f2-bafe-18958855d572` | IfCondition:If Condition1 -> Lookup:check_last_run_status -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> IfCondition:conditionally_update_pp_audit | ON Cron every 15m (Central Standard Time; end 2026-12-31) | 1001 tot / 1001 ok / 0 fail | - |
| `pp_orchestration_without_pp_audit_old` | `f9c79bd2-9d0b-48ee-8400-f79803191626` | IfCondition:If Condition1 -> Lookup:check_last_run_status -> Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time | none | 0 tot / 0 ok / 0 fail | - |
| `pp_orchestrator_test` | `678c340c-0df7-4118-90ee-4e21bda10657` | IfCondition:If Condition -> Script:pipeline_end_audit_log -> Lookup:check_last_run_status | off Cron every 15m (India Standard Time; end 2025-07-28) | 0 tot / 0 ok / 0 fail | gbp-data-pipeline |

## Staging to dimension (`pp_load_stg_to_dim_*`) (46)

| Pipeline | ID | Top activities | Schedule | Recent runs | Connections |
|---|---|---|---|---|---|
| `pp_load_stg_to_dim_company` | `5c818282-6189-4630-9435-962f7764e27a` | Lookup:lkp_last_modified_date -> SetVariable:set_failed_activity_to_lkp -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> IfCondition:check_load_type -> SqlServerStoredProcedure:sp_call_increamental_load ... | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_company_audit` | `dce36176-b4c7-464f-9eb2-f7d39ebb73c6` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_company_full` | `55acbbd2-a332-45f6-9237-e33caac4244d` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 3 tot / 3 ok / 0 fail | - |
| `pp_load_stg_to_dim_company_no_audit` | `5235ef05-d996-46ef-bd7b-54156e6d433d` | SqlServerStoredProcedure:sp_call_increamental_load | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_division` | `c0b03c9f-01f4-4872-889f-41f0fa6bfaa7` | Lookup:lkp_last_modified_date -> SetVariable:set_failed_activity_to_lkp -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> IfCondition:check_load_type -> SqlServerStoredProcedure:sp_call_increamental_load ... | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_division_audit` | `4058be90-a6c5-4ac1-9cd9-5e6cc77aaaf4` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_division_full` | `4b64090a-03e1-4011-b0be-ab3035011706` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 3 tot / 3 ok / 0 fail | - |
| `pp_load_stg_to_dim_division_no_audit` | `fe2673ee-33b4-4ddd-b25f-1bb92c8be82d` | SqlServerStoredProcedure:sp_call_increamental_load | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_job` | `3d60910f-4159-4cb4-81b0-96af73d87a11` | Lookup:lkp_last_modified_date -> SetVariable:set_failed_activity_to_lkp -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> IfCondition:check_load_type -> SqlServerStoredProcedure:sp_call_increamental_load ... | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_job_audit` | `1596291f-7bee-492d-af09-ebeb52a9712a` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_job_full` | `764ce173-dabd-414c-ad78-038260631ef4` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 3 tot / 3 ok / 0 fail | - |
| `pp_load_stg_to_dim_job_no_audit` | `0ef1aa73-e832-4625-b2b0-27a9cfe197dc` | SqlServerStoredProcedure:sp_call_increamental_load | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_job_task` | `ef4ecda2-e214-47f5-8a49-6f105781aa91` | Lookup:lkp_last_modified_date -> SetVariable:set_failed_activity_to_lkp -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> IfCondition:check_load_type -> SqlServerStoredProcedure:sp_call_increamental_load ... | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_job_task_audit` | `7aad0c95-6a59-4d24-838e-71eeb7aaa318` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_job_task_full` | `90634c30-6634-4eec-afeb-a62a814999df` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 3 tot / 3 ok / 0 fail | - |
| `pp_load_stg_to_dim_job_task_no_audit` | `78f9d9fa-3230-4dc6-b2de-db0691bff109` | SqlServerStoredProcedure:sp_call_increamental_load | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_lot` | `2d689279-eb37-4ff8-ba26-ac44878a8b20` | Lookup:lkp_last_modified_date -> SetVariable:set_failed_activity_to_lkp -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> IfCondition:check_load_type -> SqlServerStoredProcedure:sp_call_increamental_load ... | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_lot_audit` | `0d3a09de-87e8-4145-905c-35f9515c4480` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_lot_full` | `57ea45c2-cd26-4a4d-87ef-1a9489a8feb1` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 3 tot / 3 ok / 0 fail | - |
| `pp_load_stg_to_dim_lot_no_audit` | `41bf8e05-c07f-4df5-b519-4e878326f37c` | SqlServerStoredProcedure:sp_call_increamental_load | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_major_minor` | `0a1b3ca5-495c-4016-ae7e-f80fb0590ff4` | Lookup:lkp_last_modified_date -> SetVariable:set_failed_activity_to_lkp -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> IfCondition:check_load_type -> SqlServerStoredProcedure:sp_call_increamental_load ... | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_major_minor_audit` | `09d93440-86da-4ee5-baea-dcedff9c2901` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_major_minor_full` | `37fe7e20-c54a-40f7-a147-776e1db3a309` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 3 tot / 3 ok / 0 fail | - |
| `pp_load_stg_to_dim_major_minor_no_audit` | `d55b46d5-307f-4cbb-baf8-192d569075ae` | SqlServerStoredProcedure:sp_call_increamental_load | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_operating_unit` | `b54303c8-50e1-43d3-9dae-d1afc46f3414` | Lookup:lkp_last_modified_date -> Script:pipeline_end_audit_log -> SetVariable:set_failed_activity_to_lkp -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> IfCondition:check_load_type ... | off Daily @06:00 (Central Standard Time; end 2025-05-23) | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_operating_unit_audit` | `4b0d19e4-3cb1-4df9-abee-f77dec47fecd` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_operating_unit_full` | `4eeedd29-dbfd-4adf-bd84-a06645a02d1a` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 3 tot / 3 ok / 0 fail | - |
| `pp_load_stg_to_dim_operating_unit_no_audit` | `7dbd5f46-f018-4712-9d9d-6c4f39641f44` | SqlServerStoredProcedure:sp_call_increamental_load | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_period` | `18eb302b-dc12-4acd-84c4-2b1bf154f8e7` | Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp -> Script:pipeline_end_audit_log | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_period_audit` | `a20a3d12-9faf-4d0d-a09f-54d5c1babfaf` | Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp -> Script:pipeline_end_audit_log | none | 3 tot / 3 ok / 0 fail | - |
| `pp_load_stg_to_dim_period_no_audit` | `5db813ca-ba19-41b8-8a9c-af3a7eab9890` | SqlServerStoredProcedure:sp_call_increamental_load | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_project` | `578fa5ee-e93f-4d42-8998-fa1990fa9e27` | Lookup:lkp_last_modified_date -> SetVariable:set_failed_activity_to_lkp -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> IfCondition:check_load_type -> SqlServerStoredProcedure:sp_call_increamental_load ... | ON Daily @06:00 (Central Standard Time; end 2025-05-23) | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_project_audit` | `f30842fa-819b-4780-9f20-f72ad4e65e2b` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_project_full` | `dcae30fd-f7de-4adb-9d5c-5e3579fe3566` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 3 tot / 3 ok / 0 fail | - |
| `pp_load_stg_to_dim_project_no_audit` | `2ee1f343-0540-4da4-a98f-6f5a7d1251ec` | SqlServerStoredProcedure:sp_call_increamental_load | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_sale` | `c68322b2-b04c-4bf0-9861-0d8acc0a22a9` | Lookup:lkp_last_modified_date -> SetVariable:set_failed_activity_to_lkp -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> IfCondition:check_load_type -> SqlServerStoredProcedure:sp_call_increamental_load ... | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_sale_audit` | `6a7e5e37-408f-447d-872b-a0dcca063b06` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_sale_full` | `2e270b8d-bfb5-4ecd-849f-090a591e8dbb` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 3 tot / 3 ok / 0 fail | - |
| `pp_load_stg_to_dim_sale_no_audit` | `1248eeb9-afaa-461f-8028-c9e4c1efd877` | SqlServerStoredProcedure:sp_call_increamental_load | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_sale_transfer` | `21cae554-fafa-4c62-a57a-dd3377aeb8c8` | Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp -> Script:pipeline_end_audit_log | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_sale_transfer_audit` | `67d82fee-096c-4ace-b42a-3153698075ef` | Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp -> Script:pipeline_end_audit_log | none | 3 tot / 3 ok / 0 fail | - |
| `pp_load_stg_to_dim_sale_transfer_no_audit` | `56c4cb71-3146-48ce-a256-bae55b682387` | SqlServerStoredProcedure:sp_call_increamental_load | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_sgm_map` | `44154a39-99be-4892-b77a-808498540c27` | Lookup:lkp_last_modified_date -> SetVariable:set_failed_activity_to_lkp -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> IfCondition:check_load_type -> SqlServerStoredProcedure:sp_call_increamental_load ... | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_sgm_map_audit` | `f10c53ae-4679-4e60-b19b-ad37d4c73a68` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_dim_sgm_map_full` | `d431bf4a-9b35-4a8b-a7e0-cb0e5eb06682` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 3 tot / 3 ok / 0 fail | - |
| `pp_load_stg_to_dim_sgm_map_no_audit` | `98e2a15b-3dfc-47f1-ae10-52a82d0e7869` | SqlServerStoredProcedure:sp_call_increamental_load | none | 0 tot / 0 ok / 0 fail | - |

## Staging to fact (`pp_load_stg_to_fact_*`) (19)

| Pipeline | ID | Top activities | Schedule | Recent runs | Connections |
|---|---|---|---|---|---|
| `pp_load_stg_to_fact_general_ledger` | `f71eae63-590f-4b5a-bddb-64e23902b0fa` | Lookup:lkp_last_modified_date -> IfCondition:If Condition | none | 0 tot / 0 ok / 0 fail | GBP-Enterprise;HBLive;GB Azure SQL Authentication |
| `pp_load_stg_to_fact_general_ledger_audit` | `eac57a6a-5704-4440-ac64-9c9b32c4a2f9` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_fact_general_ledger_full` | `6d2c85d6-938a-4e47-b421-c34a510eb681` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 3 tot / 3 ok / 0 fail | - |
| `pp_load_stg_to_fact_general_ledger_no_audit` | `c683c03e-a80b-40d5-b854-4fa40f21d58d` | SqlServerStoredProcedure:sp_call_increamental_load | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_fact_lot_financials` | `8c8f4b2c-086f-4e0a-bb29-27c19e36ff76` | Lookup:lkp_last_modified_date -> IfCondition:If Condition | none | 0 tot / 0 ok / 0 fail | GBP-Enterprise;HBLive;GB Azure SQL Authentication |
| `pp_load_stg_to_fact_lot_financials_audit` | `479c8589-141b-4a38-9ba3-9867fe55a171` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_fact_lot_financials_full` | `f6168e29-ddcf-4dd4-a842-37fbce892e39` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 3 tot / 3 ok / 0 fail | - |
| `pp_load_stg_to_fact_lot_financials_hist` | `29bb0a45-7929-43a5-b79c-da010a9408b2` | Lookup:lkp_last_modified_date -> IfCondition:If Condition | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_fact_lot_financials_no_audit` | `0f4f7a0d-8b6f-473c-b655-87d047843863` | SqlServerStoredProcedure:sp_call_increamental_load | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_fact_lot_sgm` | `531332e6-3594-4bc3-8a98-1a3bc98c92de` | Lookup:lkp_last_modified_date -> IfCondition:If Condition | none | 0 tot / 0 ok / 0 fail | GBP-Enterprise;HBLive;GB Azure SQL Authentication |
| `pp_load_stg_to_fact_lot_sgm_audit` | `8ddfe426-c1c4-45fa-bcb0-451a6fc083f8` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_fact_lot_sgm_full` | `9a7a1893-cccc-4a54-80ad-cc3f66a14fdb` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 3 tot / 3 ok / 0 fail | - |
| `pp_load_stg_to_fact_lot_sgm_hist` | `1c2f2d22-5f05-4563-9ca1-252d1076330a` | Lookup:lkp_last_modified_date -> IfCondition:If Condition | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_fact_lot_sgm_no_audit` | `df3b618d-389d-41f5-b224-d2450245ff38` | SqlServerStoredProcedure:sp_call_increamental_load | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_fact_sgm_assumptions` | `933848ea-1069-47c3-ade8-487f850c7ee3` | SqlServerStoredProcedure:sp_call_increamental_load | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_fact_sgm_assumptions_audit` | `b8c76fe7-1d94-41d4-a7ab-7b2d0d8f9b3d` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_fact_sgm_assumptions_full` | `844d2d57-46a8-4b42-ae60-9c20502f2988` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 3 tot / 3 ok / 0 fail | - |
| `pp_load_stg_to_fact_sgm_assumptions_hist` | `b8d0917d-915d-4376-8403-c26ef47f4981` | Lookup:lkp_last_modified_date -> IfCondition:If Condition | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_stg_to_fact_sgm_assumptions_no_audit` | `8c4fcfd7-a729-48ee-8bec-a61cfe501b1e` | SqlServerStoredProcedure:sp_call_increamental_load | none | 0 tot / 0 ok / 0 fail | - |

## Fact history loaders (4)

| Pipeline | ID | Top activities | Schedule | Recent runs | Connections |
|---|---|---|---|---|---|
| `pp_fact_hist_scheduled` | `21040099-0634-44a1-a532-c21927b49c3c` | IfCondition:run_criteria | ON Daily @00:00 (Central Standard Time; end 2025-12-31) | 0 tot / 0 ok / 0 fail | gbp-data-pipeline |
| `pp_load_fact_lot_financials_to_fact_lot_financials_hist` | `5535a19d-0e92-4bea-85f8-30f512a197ff` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_fact_lot_sgm_to_fact_lot_sgm_hist` | `2b065f38-d2d5-40d7-9c18-6ef8c62c7458` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp | none | 0 tot / 0 ok / 0 fail | - |
| `pp_load_fact_sgm_assumptions_to_fact_sgm_assumptions_hist` | `e5ea70f0-9daa-4d22-b466-d1927b85ce76` | Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SetVariable:set_failed_activity_to_sp -> SqlServerStoredProcedure:sp_call_increamental_load | none | 0 tot / 0 ok / 0 fail | - |

## Salesforce (9)

| Pipeline | ID | Top activities | Schedule | Recent runs | Connections |
|---|---|---|---|---|---|
| `pp_fabric_salesforce_ingestion_bkp1` | `87fb3c8a-d143-4e89-aadb-365bdc177664` | Lookup:lkp_get_tablelist -> ForEach:foreach_updates -> ForEach:foreach_inserts -> Filter:filter_updates -> Filter:filter_inserts | none | 0 tot / 0 ok / 0 fail | Salesforce_UAT |
| `pp_fabric_salesforce_ingestion_prod` | `e12fc780-d609-4361-8f07-24c3c3e71e48` | Lookup:lkp_get_tablelist -> ForEach:foreach | off Cron every 10m (Central Standard Time; end 2029-12-31) | 444 tot / 330 ok / 111 fail / 3 other | Salesforce_Prod |
| `pp_fabric_salesforce_ingestion_UAT` | `53eafa23-06a1-4ad3-9f2a-5ab4e1b6eeec` | Lookup:lkp_get_tablelist -> ForEach:foreach | none | 0 tot / 0 ok / 0 fail | Salesforce_UAT |
| `pp_salesforce_fabric_ingestion` | `944a7184-4d26-4e45-b815-11ac2ee393e3` | Lookup:lkp_table_list -> ForEach:foreach_salesforceobjects | off Cron every 10m (Central Standard Time; end 2029-12-31) | 0 tot / 0 ok / 0 fail | Salesforce_UAT |
| `pp_salesforce_fabric_ingestion_bkp1` | `4b00092e-c22d-4de9-871f-3e2e191f9d10` | Lookup:lkp_table_list -> ForEach:foreach_salesforceobjects -> Copy:copy_salesforce_fabric_copy1 | none | 0 tot / 0 ok / 0 fail | Salesforce_UAT |
| `pp_salesforce_fabric_ingestion_prod` | `22a02d16-b512-4f89-91f1-89b046c86028` | Lookup:lkp_table_list -> ForEach:foreach_salesforceobjects | none | 331 tot / 329 ok / 2 fail | Salesforce_Prod |
| `pp_salesforce_fabric_ingestion_test` | `362d2c01-61e0-418f-bac0-07386fab47a1` | Lookup:lkp_table_list -> SetVariable:Set variable1 -> SetVariable:Set variable2 -> SetVariable:Set variable3 -> SetVariable:Set variable4 -> Copy:copy_salesforce_fabric_copy1 -> Copy:Copy data1 | none | 0 tot / 0 ok / 0 fail | Salesforce_UAT |
| `pp_salesforce_fabric_ingestion_UAT` | `a34cf9d7-effb-44e4-a479-1b0d8b509377` | Lookup:lkp_table_list -> ForEach:foreach_salesforceobjects -> Copy:copy_salesforce_fabric_copy1 | none | 1 tot / 1 ok / 0 fail | Salesforce_UAT |
| `pp_salesforce_orchestrator_prod` | `2ff24d32-6afa-43c0-842c-55eef794cd77` | InvokePipeline:fabric_to_salesforce -> InvokePipeline:salesforce_to_fabric -> InvokePipeline:load_views_to_csv | none | 429 tot / 326 ok / 100 fail / 3 other | gbp-data-pipeline |

## Utilities and other (6)

| Pipeline | ID | Top activities | Schedule | Recent runs | Connections |
|---|---|---|---|---|---|
| `pp_audit_cleanup` | `b1f9cebd-7397-4634-b974-7a291f70f5a9` | SqlServerStoredProcedure:sp_call_audit_cleanup | ON Daily @00:00 (Central Standard Time; end 2025-12-31) | 0 tot / 0 ok / 0 fail | - |
| `pp_compare_azure_vs_mirrored_db` | `e034c1e2-bd47-4562-9e74-db39743fec96` | Lookup:Get Load Date -> Script:Truncate Column-Row Validation Table -> SetVariable:Set created_date -> Copy:Target DB Column Validation -> Copy:HBLive Source DB Column Validation -> Copy:SPLive Source DB Column Validation -> Copy:BuildPro Source DB Column Validation -> Copy:Target DB Row Validation ... | ON Daily @06:30 (Eastern Standard Time; end 2025-12-31) | 0 tot / 0 ok / 0 fail | GBP-Enterprise;HBLive;GB Azure SQL Authentication, gbpsql01.database.windows.net;BuildPro;GB Azure SQL Authentication, gbpsql01.database.windows.net;SPLive;GB Azure SQL Authentication, gbpsql01.database.windows.net;HBLive;GB Azure SQL Authentication |
| `pp_delete_blocked_logs` | `29b8a417-0bb2-4f19-8972-00e0a24487cb` | Script:delete_blocked_log | ON Cron every 120m (India Standard Time; end 2027-03-26) | 369 tot / 369 ok / 0 fail | - |
| `pp_load_view_to_csv` | `707d2933-5bad-46f6-8d27-a9fea2aa2ca7` | Lookup:lkp_get_ounit_codes -> ForEach:foreach_ounit_codes -> Copy:NSE_WorkOrder_Import_to_csv | none | 326 tot / 326 ok / 0 fail | ADLS kradhakrishnan |
| `pp_load_zonda_to_fabric` | `ec029d90-9d22-4b2d-8ea3-0a33e129b7a4` | TridentNotebook:get_credentials -> TridentNotebook:load_community -> TridentNotebook:load_plans -> TridentNotebook:load_lots | none | 0 tot / 0 ok / 0 fail | - |
| `pp_temp_schema_discovery` | `d30a42ee-ce1a-4176-a46c-db433ea555b8` | Copy:Copy data1 | none | 2 tot / 2 ok / 0 fail | Salesforce_Prod |

## Detail notes (orchestrators, salesforce, utilities)

### `pp_audit_cleanup`
- **ID:** `b1f9cebd-7397-4634-b974-7a291f70f5a9`
- **Activity types:** `{'SqlServerStoredProcedure': 1}`
- **Top-level flow:** SqlServerStoredProcedure:sp_call_audit_cleanup
- **Artifacts in definition:** `EDW_Silver.Warehouse`
- **Schedule:** ON Daily @00:00 (Central Standard Time; end 2025-12-31)
- **Runs:** 0 tot / 0 ok / 0 fail

### `pp_compare_azure_vs_mirrored_db`
- **ID:** `e034c1e2-bd47-4562-9e74-db39743fec96`
- **Activity types:** `{'Lookup': 1, 'Script': 3, 'SetVariable': 1, 'Copy': 8, 'SqlServerStoredProcedure': 1, 'IfCondition': 2, 'Office365Outlook': 2}`
- **Top-level flow:** Lookup:Get Load Date -> Script:Truncate Column-Row Validation Table -> SetVariable:Set created_date -> Copy:Target DB Column Validation -> Copy:HBLive Source DB Column Validation -> Copy:SPLive Source DB Column Validation -> Copy:BuildPro Source DB Column Validation -> Copy:Target DB Row Validation ...
- **Connections:**
  - `GBP-Enterprise;HBLive;GB Azure SQL Authentication` (ShareableCloud) cx2knzbh2yrejngvheequwseqy-mpsfzbl7atie7hr6l3lpvtholy.datawarehouse.fabric.microsoft.com;HBLive id=`1fb4612f-0037-45df-b766-1722b10aeced`
  - `gbpsql01.database.windows.net;BuildPro;GB Azure SQL Authentication` (ShareableCloud) gbpsql01.database.windows.net;BuildPro id=`5c15c167-50da-4330-b9a6-88c60f4469ec`
  - `gbpsql01.database.windows.net;SPLive;GB Azure SQL Authentication` (ShareableCloud) gbpsql01.database.windows.net;SPLive id=`76b1e81c-0b05-4c46-9b80-1f0003c8534b`
  - `gbpsql01.database.windows.net;HBLive;GB Azure SQL Authentication` (ShareableCloud) gbpsql01.database.windows.net;HBLive id=`dbd5bba6-e89b-44c5-a43c-92f496b3ca76`
- **Artifacts in definition:** `EDW_Silver.Warehouse`
- **Variables:** ['source_db', 'target_db', 'created_date']
- **Schedule:** ON Daily @06:30 (Eastern Standard Time; end 2025-12-31)
- **Runs:** 0 tot / 0 ok / 0 fail

### `pp_delete_blocked_logs`
- **ID:** `29b8a417-0bb2-4f19-8972-00e0a24487cb`
- **Activity types:** `{'Script': 1}`
- **Top-level flow:** Script:delete_blocked_log
- **Artifacts in definition:** `EDW_Silver.Warehouse`
- **Schedule:** ON Cron every 120m (India Standard Time; end 2027-03-26)
- **Runs:** 369 tot / 369 ok / 0 fail
  - 2026-07-15T16:44:01.8566667 -> 2026-07-15T16:44:24.0733333 | Completed | Scheduled
  - 2026-07-15T14:44:00.44 -> 2026-07-15T14:44:20.9566667 | Completed | Scheduled
  - 2026-07-15T12:44:01.3066667 -> 2026-07-15T12:44:20.72 | Completed | Scheduled
  - 2026-07-15T10:44:01.2766667 -> 2026-07-15T10:44:24.4466667 | Completed | Scheduled
  - 2026-07-15T08:44:01.9333333 -> 2026-07-15T08:44:22.3666667 | Completed | Scheduled

### `pp_fabric_salesforce_ingestion_bkp1`
- **ID:** `87fb3c8a-d143-4e89-aadb-365bdc177664`
- **Activity types:** `{'Lookup': 2, 'ForEach': 2, 'Copy': 2, 'SetVariable': 3, 'Script': 6, 'Filter': 2}`
- **Top-level flow:** Lookup:lkp_get_tablelist -> ForEach:foreach_updates -> ForEach:foreach_inserts -> Filter:filter_updates -> Filter:filter_inserts
- **Connections:**
  - `Salesforce_UAT` (ShareableCloud) https://greenbrick--uat.sandbox.my.salesforce.com/ id=`37551f20-232c-4133-ae10-9b04df2d6f7f`
- **Artifacts in definition:** `Salesforce_WH.Warehouse`
- **Variables:** ['v_LastModifiedDate', 'LogId']
- **Schedule:** none
- **Runs:** 0 tot / 0 ok / 0 fail

### `pp_fabric_salesforce_ingestion_prod`
- **ID:** `e12fc780-d609-4361-8f07-24c3c3e71e48`
- **Activity types:** `{'Lookup': 1, 'ForEach': 1, 'Switch': 1, 'Copy': 2, 'Script': 4, 'Fail': 1}`
- **Top-level flow:** Lookup:lkp_get_tablelist -> ForEach:foreach
- **Connections:**
  - `Salesforce_Prod` (ShareableCloud) https://greenbrick.my.salesforce.com/ id=`207e8644-adf2-4e53-97d7-b14f9679bce4`
- **Artifacts in definition:** `Salesforce_WH.Warehouse`
- **Variables:** ['v_LastModifiedDate']
- **Schedule:** off Cron every 10m (Central Standard Time; end 2029-12-31)
- **Runs:** 444 tot / 330 ok / 111 fail / 3 other
  - 2026-07-15T17:48:18.266856 -> 2026-07-15T17:57:02.18 | Completed | Manual
  - 2026-07-15T16:48:20.806792 -> 2026-07-15T16:56:44.2666667 | Completed | Manual
  - 2026-07-15T15:48:20.3653466 -> 2026-07-15T15:56:47.36 | Completed | Manual
  - 2026-07-15T14:48:18.6503382 -> 2026-07-15T14:56:13.4066667 | Completed | Manual
  - 2026-07-15T13:48:23.2936378 -> 2026-07-15T13:56:28.54 | Completed | Manual

### `pp_fabric_salesforce_ingestion_UAT`
- **ID:** `53eafa23-06a1-4ad3-9f2a-5ab4e1b6eeec`
- **Activity types:** `{'Lookup': 1, 'ForEach': 1, 'Switch': 1, 'Copy': 2, 'Script': 4, 'Fail': 1}`
- **Top-level flow:** Lookup:lkp_get_tablelist -> ForEach:foreach
- **Connections:**
  - `Salesforce_UAT` (ShareableCloud) https://greenbrick--uat.sandbox.my.salesforce.com/ id=`37551f20-232c-4133-ae10-9b04df2d6f7f`
- **Artifacts in definition:** `Salesforce_WH_UAT.Warehouse`, `Salesforce_WH.Warehouse`
- **Variables:** ['v_LastModifiedDate']
- **Schedule:** none
- **Runs:** 0 tot / 0 ok / 0 fail

### `pp_fact_hist_scheduled`
- **ID:** `21040099-0634-44a1-a532-c21927b49c3c`
- **Activity types:** `{'IfCondition': 1, 'InvokePipeline': 3}`
- **Top-level flow:** IfCondition:run_criteria
- **Invokes:**
  - `fact_lot_financials_hist` -> `pp_load_fact_lot_financials_to_fact_lot_financials_hist` (wait=True)
  - `fact_sgm_assumptions_hist` -> `pp_load_fact_sgm_assumptions_to_fact_sgm_assumptions_hist` (wait=True)
  - `fact_lot_sgm_hist` -> `pp_load_fact_lot_sgm_to_fact_lot_sgm_hist` (wait=True)
- **Connections:**
  - `gbp-data-pipeline` (ShareableCloud) FabricDataPipelines id=`50db2697-5602-4de2-9834-a8a3ab0f4158`
- **Variables:** ['condition']
- **Schedule:** ON Daily @00:00 (Central Standard Time; end 2025-12-31)
- **Runs:** 0 tot / 0 ok / 0 fail

### `pp_load_fact_lot_financials_to_fact_lot_financials_hist`
- **ID:** `5535a19d-0e92-4bea-85f8-30f512a197ff`
- **Activity types:** `{'Script': 2, 'Lookup': 1, 'SetVariable': 3, 'SqlServerStoredProcedure': 1}`
- **Top-level flow:** Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp
- **Artifacts in definition:** `EDW_Silver.Warehouse`
- **Parameters:** ['p_type_of_run', 'p_orchestrator_audit_id']
- **Variables:** ['v_max_last_modified_date', 'v_failed_activity', 'v_pipeline_audit_id', 'v_start_time', 'v_load_type']
- **Schedule:** none
- **Runs:** 0 tot / 0 ok / 0 fail

### `pp_load_fact_lot_sgm_to_fact_lot_sgm_hist`
- **ID:** `2b065f38-d2d5-40d7-9c18-6ef8c62c7458`
- **Activity types:** `{'Script': 2, 'Lookup': 1, 'SetVariable': 3, 'SqlServerStoredProcedure': 1}`
- **Top-level flow:** Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SqlServerStoredProcedure:sp_call_increamental_load -> SetVariable:set_failed_activity_to_sp
- **Artifacts in definition:** `EDW_Silver.Warehouse`
- **Parameters:** ['p_type_of_run', 'p_orchestrator_audit_id']
- **Variables:** ['v_max_last_modified_date', 'v_failed_activity', 'v_pipeline_audit_id', 'v_start_time', 'v_load_type']
- **Schedule:** none
- **Runs:** 0 tot / 0 ok / 0 fail

### `pp_load_fact_sgm_assumptions_to_fact_sgm_assumptions_hist`
- **ID:** `e5ea70f0-9daa-4d22-b466-d1927b85ce76`
- **Activity types:** `{'Script': 2, 'Lookup': 1, 'SetVariable': 3, 'SqlServerStoredProcedure': 1}`
- **Top-level flow:** Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> SetVariable:set_auditid_via_manual_run -> SetVariable:set_start_time_via_manual_run -> SetVariable:set_failed_activity_to_sp -> SqlServerStoredProcedure:sp_call_increamental_load
- **Artifacts in definition:** `EDW_Silver.Warehouse`
- **Parameters:** ['p_type_of_run', 'p_orchestrator_audit_id']
- **Variables:** ['v_max_last_modified_date', 'v_failed_activity', 'v_pipeline_audit_id', 'v_start_time', 'v_load_type']
- **Schedule:** none
- **Runs:** 0 tot / 0 ok / 0 fail

### `pp_load_view_to_csv`
- **ID:** `707d2933-5bad-46f6-8d27-a9fea2aa2ca7`
- **Activity types:** `{'Lookup': 1, 'ForEach': 1, 'Copy': 2}`
- **Top-level flow:** Lookup:lkp_get_ounit_codes -> ForEach:foreach_ounit_codes -> Copy:NSE_WorkOrder_Import_to_csv
- **Connections:**
  - `ADLS kradhakrishnan` (ShareableCloud) https://gbpintegrationfiles.dfs.core.windows.net/ id=`9c7c107d-1f76-4a97-8b25-eb61a9923260`
- **Artifacts in definition:** `Salesforce_WH.Warehouse`
- **Schedule:** none
- **Runs:** 326 tot / 326 ok / 0 fail
  - 2026-07-15T18:07:41.62 -> 2026-07-15T18:08:38.0233333 | Completed | Manual
  - 2026-07-15T17:10:24.9171885 -> 2026-07-15T17:11:37.4233333 | Completed | Manual
  - 2026-07-15T16:10:22.4786717 -> 2026-07-15T16:11:28.5933333 | Completed | Manual
  - 2026-07-15T15:10:30.1133333 -> 2026-07-15T15:11:40.3633333 | Completed | Manual
  - 2026-07-15T14:06:57.1830388 -> 2026-07-15T14:08:01.0329497 | Completed | Manual

### `pp_load_zonda_to_fabric`
- **ID:** `ec029d90-9d22-4b2d-8ea3-0a33e129b7a4`
- **Activity types:** `{'TridentNotebook': 4}`
- **Top-level flow:** TridentNotebook:get_credentials -> TridentNotebook:load_community -> TridentNotebook:load_plans -> TridentNotebook:load_lots
- **Schedule:** none
- **Runs:** 0 tot / 0 ok / 0 fail

### `pp_orchestration`
- **ID:** `17465852-a4ab-492e-b950-1050ed800d74`
- **Activity types:** `{'InvokePipeline': 14}`
- **Top-level flow:** InvokePipeline:dim_job_task -> InvokePipeline:dim_sale_transfer -> InvokePipeline:dim_job -> InvokePipeline:dim_sale -> InvokePipeline:dim_lot -> InvokePipeline:dim_major_minor -> InvokePipeline:fact_general_ledger -> InvokePipeline:dim_sgm_map ...
- **Invokes:**
  - `dim_job_task` -> `pp_load_stg_to_dim_job_task` (wait=True)
  - `dim_sale_transfer` -> `pp_load_stg_to_dim_sale_transfer` (wait=True)
  - `dim_job` -> `pp_load_stg_to_dim_job` (wait=True)
  - `dim_sale` -> `pp_load_stg_to_dim_sale` (wait=True)
  - `dim_lot` -> `pp_load_stg_to_dim_lot` (wait=True)
  - `dim_major_minor` -> `pp_load_stg_to_dim_major_minor` (wait=True)
  - `fact_general_ledger` -> `pp_load_stg_to_fact_general_ledger` (wait=True)
  - `dim_sgm_map` -> `pp_load_stg_to_dim_sgm_map` (wait=True)
  - `fact_lot_financials` -> `pp_load_stg_to_fact_lot_financials` (wait=True)
  - `dim_company` -> `pp_load_stg_to_dim_company` (wait=True)
  - `dim_division` -> `pp_load_stg_to_dim_division` (wait=True)
  - `dim_period` -> `pp_load_stg_to_dim_period` (wait=True)
  - `dim_operating_unit` -> `pp_load_stg_to_dim_operating_unit` (wait=True)
  - `dim_project` -> `pp_load_stg_to_dim_project` (wait=True)
- **Connections:**
  - `gbp-data-pipeline` (ShareableCloud) FabricDataPipelines id=`50db2697-5602-4de2-9834-a8a3ab0f4158`
- **Schedule:** off Cron every 15m (Central Standard Time; end 2025-12-31)
- **Runs:** 0 tot / 0 ok / 0 fail

### `pp_orchestration_full`
- **ID:** `22b96108-4107-427c-a468-80e8acbb1286`
- **Activity types:** `{'IfCondition': 1, 'Fail': 1, 'SetVariable': 18, 'InvokePipeline': 16, 'Lookup': 2, 'Script': 2}`
- **Top-level flow:** IfCondition:If Condition1 -> Lookup:check_last_run_status -> Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time
- **Invokes:**
  - `dim_job_task` -> `pp_load_stg_to_dim_job_task_full` (wait=True)
  - `dim_sale_transfer` -> `pp_load_stg_to_dim_sale_transfer_audit` (wait=True)
  - `dim_job` -> `pp_load_stg_to_dim_job_full` (wait=True)
  - `dim_sale` -> `pp_load_stg_to_dim_sale_full` (wait=True)
  - `dim_lot` -> `pp_load_stg_to_dim_lot_full` (wait=True)
  - `dim_major_minor` -> `pp_load_stg_to_dim_major_minor_full` (wait=True)
  - `fact_general_ledger` -> `pp_load_stg_to_fact_general_ledger_full` (wait=True)
  - `dim_sgm_map` -> `pp_load_stg_to_dim_sgm_map_full` (wait=True)
  - `fact_lot_financials` -> `pp_load_stg_to_fact_lot_financials_full` (wait=True)
  - `dim_company` -> `pp_load_stg_to_dim_company_full` (wait=True)
  - `dim_division` -> `pp_load_stg_to_dim_division_full` (wait=True)
  - `dim_period` -> `pp_load_stg_to_dim_period_audit` (wait=True)
  - `dim_operating_unit` -> `pp_load_stg_to_dim_operating_unit_full` (wait=True)
  - `dim_project` -> `pp_load_stg_to_dim_project_full` (wait=True)
  - `fact_sgm_assumptions` -> `pp_load_stg_to_fact_sgm_assumptions_full` (wait=True)
  - `fact_lot sgm` -> `pp_load_stg_to_fact_lot_sgm_full` (wait=True)
- **Connections:**
  - `gbp-data-pipeline` (ShareableCloud) FabricDataPipelines id=`50db2697-5602-4de2-9834-a8a3ab0f4158`
- **Artifacts in definition:** `EDW_Silver.Warehouse`
- **Variables:** ['v_load_type', 'v_pipeline_audit_id', 'v_dim_company_failed_activity', 'v_dim_division_failed_activity', 'v_dim_period_failed_activity', 'v_dim_operating_unit_failed_activity', 'v_dim_project_failed_activity', 'v_dim_job_task_failed_activity', 'v_dim_sale_transfer_failed_activity', 'v_dim_major_minor_failed_activity', 'v_dim_sgm_map_failed_activity', 'v_dim_job_failed_activity', 'v_dim_sale_failed_activity', 'v_dim_lot_failed_activity', 'v_fact_general_ledger_failed_activity', 'v_fact_lot_financials_failed_activity', 'v_failed_activity', 'v_fact_sgm_assumptions_failed_activity', 'v_fact_lot_sgm_failed_activity']
- **Schedule:** none
- **Runs:** 3 tot / 3 ok / 0 fail
  - 2026-06-17T01:59:36.7460563 -> 2026-06-17T02:35:22.6388227 | Completed | Manual
  - 2026-06-17T00:56:44.7868871 -> 2026-06-17T01:31:59.9589137 | Completed | Manual
  - 2026-06-16T09:20:20.7911142 -> 2026-06-16T09:54:40.8066513 | Completed | Manual

### `pp_orchestration_with_pp_audit`
- **ID:** `e9201dd4-fccb-4e42-8884-64970fb5fa6e`
- **Activity types:** `{'IfCondition': 1, 'Fail': 1, 'SetVariable': 18, 'InvokePipeline': 16, 'Lookup': 2, 'Script': 2}`
- **Top-level flow:** IfCondition:If Condition1 -> Lookup:check_last_run_status -> Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time
- **Invokes:**
  - `dim_job_task` -> `pp_load_stg_to_dim_job_task_audit` (wait=True)
  - `dim_sale_transfer` -> `pp_load_stg_to_dim_sale_transfer_audit` (wait=True)
  - `dim_job` -> `pp_load_stg_to_dim_job_audit` (wait=True)
  - `dim_sale` -> `pp_load_stg_to_dim_sale_audit` (wait=True)
  - `dim_lot` -> `pp_load_stg_to_dim_lot_audit` (wait=True)
  - `dim_major_minor` -> `pp_load_stg_to_dim_major_minor_audit` (wait=True)
  - `fact_general_ledger` -> `pp_load_stg_to_fact_general_ledger_audit` (wait=True)
  - `dim_sgm_map` -> `pp_load_stg_to_dim_sgm_map_audit` (wait=True)
  - `fact_lot_financials` -> `pp_load_stg_to_fact_lot_financials_audit` (wait=True)
  - `dim_company` -> `pp_load_stg_to_dim_company_audit` (wait=True)
  - `dim_division` -> `pp_load_stg_to_dim_division_audit` (wait=True)
  - `dim_period` -> `pp_load_stg_to_dim_period_audit` (wait=True)
  - `dim_operating_unit` -> `pp_load_stg_to_dim_operating_unit_audit` (wait=True)
  - `dim_project` -> `pp_load_stg_to_dim_project_audit` (wait=True)
  - `fact_sgm_assumptions` -> `pp_load_stg_to_fact_sgm_assumptions_audit` (wait=True)
  - `fact_lot_sgm` -> `pp_load_stg_to_fact_lot_sgm_audit` (wait=True)
- **Connections:**
  - `gbp-data-pipeline` (ShareableCloud) FabricDataPipelines id=`50db2697-5602-4de2-9834-a8a3ab0f4158`
- **Artifacts in definition:** `EDW_Silver.Warehouse`
- **Variables:** ['v_load_type', 'v_pipeline_audit_id', 'v_dim_company_failed_activity', 'v_dim_division_failed_activity', 'v_dim_period_failed_activity', 'v_dim_operating_unit_failed_activity', 'v_dim_project_failed_activity', 'v_dim_job_task_failed_activity', 'v_dim_sale_transfer_failed_activity', 'v_dim_major_minor_failed_activity', 'v_dim_sgm_map_failed_activity', 'v_dim_job_failed_activity', 'v_dim_sale_failed_activity', 'v_dim_lot_failed_activity', 'v_fact_general_ledger_failed_activity', 'v_fact_lot_financials_failed_activity', 'v_failed_activity', 'v_fact_sgm_assumptions_failed_activity', 'v_fact_lot_sgm_failed_activity']
- **Schedule:** off Cron every 30m (Central Standard Time; end 2026-12-17)
- **Runs:** 0 tot / 0 ok / 0 fail

### `pp_orchestration_without_pp_audit`
- **ID:** `9e2c73c1-f252-46f2-bafe-18958855d572`
- **Activity types:** `{'IfCondition': 2, 'Fail': 3, 'SetVariable': 18, 'SqlServerStoredProcedure': 16, 'Lookup': 2, 'Script': 5}`
- **Top-level flow:** IfCondition:If Condition1 -> Lookup:check_last_run_status -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time -> IfCondition:conditionally_update_pp_audit
- **Artifacts in definition:** `EDW_Silver.Warehouse`
- **Variables:** ['v_load_type', 'v_pipeline_audit_id', 'v_dim_company_failed_activity', 'v_dim_division_failed_activity', 'v_dim_period_failed_activity', 'v_dim_operating_unit_failed_activity', 'v_dim_project_failed_activity', 'v_dim_job_task_failed_activity', 'v_dim_sale_transfer_failed_activity', 'v_dim_major_minor_failed_activity', 'v_dim_sgm_map_failed_activity', 'v_dim_job_failed_activity', 'v_dim_sale_failed_activity', 'v_dim_lot_failed_activity', 'v_fact_general_ledger_failed_activity', 'v_fact_lot_financials_failed_activity', 'v_failed_activity', 'v_fact_sgm_assumptions_failed_activity', 'v_fact_lot_sgm_failed_activity']
- **Schedule:** ON Cron every 15m (Central Standard Time; end 2026-12-31)
- **Runs:** 1001 tot / 1001 ok / 0 fail
  - 2026-07-15T18:06:01.4324284 -> 2026-07-15T18:12:56.8866667 | Completed | Scheduled
  - 2026-07-15T17:51:02.3196009 -> 2026-07-15T17:57:21.18 | Completed | Scheduled
  - 2026-07-15T17:36:03.3606042 -> 2026-07-15T17:42:39.8 | Completed | Scheduled
  - 2026-07-15T17:21:01.6328463 -> 2026-07-15T17:27:18.9466667 | Completed | Scheduled
  - 2026-07-15T17:06:01.1906255 -> 2026-07-15T17:13:09.9033333 | Completed | Scheduled

### `pp_orchestration_without_pp_audit_old`
- **ID:** `f9c79bd2-9d0b-48ee-8400-f79803191626`
- **Activity types:** `{'IfCondition': 1, 'Fail': 1, 'SetVariable': 18, 'SqlServerStoredProcedure': 16, 'Lookup': 2, 'Script': 2}`
- **Top-level flow:** IfCondition:If Condition1 -> Lookup:check_last_run_status -> Script:pipeline_end_audit_log -> Script:pipeline_start_audit_log -> Lookup:generate_audit_key_and_start_time
- **Artifacts in definition:** `EDW_Silver.Warehouse`
- **Variables:** ['v_load_type', 'v_pipeline_audit_id', 'v_dim_company_failed_activity', 'v_dim_division_failed_activity', 'v_dim_period_failed_activity', 'v_dim_operating_unit_failed_activity', 'v_dim_project_failed_activity', 'v_dim_job_task_failed_activity', 'v_dim_sale_transfer_failed_activity', 'v_dim_major_minor_failed_activity', 'v_dim_sgm_map_failed_activity', 'v_dim_job_failed_activity', 'v_dim_sale_failed_activity', 'v_dim_lot_failed_activity', 'v_fact_general_ledger_failed_activity', 'v_fact_lot_financials_failed_activity', 'v_failed_activity', 'v_fact_sgm_assumptions_failed_activity', 'v_fact_lot_sgm_failed_activity']
- **Schedule:** none
- **Runs:** 0 tot / 0 ok / 0 fail

### `pp_orchestrator_test`
- **ID:** `678c340c-0df7-4118-90ee-4e21bda10657`
- **Activity types:** `{'IfCondition': 1, 'Fail': 1, 'SetVariable': 16, 'Script': 2, 'Lookup': 2, 'InvokePipeline': 14}`
- **Top-level flow:** IfCondition:If Condition -> Script:pipeline_end_audit_log -> Lookup:check_last_run_status
- **Invokes:**
  - `dim_job_task` -> `pp_load_stg_to_dim_job_task` (wait=True)
  - `dim_sale_transfer` -> `pp_load_stg_to_dim_sale_transfer` (wait=True)
  - `dim_job` -> `pp_load_stg_to_dim_job` (wait=True)
  - `dim_sale` -> `pp_load_stg_to_dim_sale` (wait=True)
  - `dim_lot` -> `pp_load_stg_to_dim_lot` (wait=True)
  - `dim_major_minor` -> `pp_load_stg_to_dim_major_minor` (wait=True)
  - `fact_general_ledger` -> `pp_load_stg_to_fact_general_ledger` (wait=True)
  - `dim_sgm_map` -> `pp_load_stg_to_dim_sgm_map` (wait=True)
  - `fact_lot_financials` -> `pp_load_stg_to_fact_lot_financials` (wait=True)
  - `dim_company` -> `pp_load_stg_to_dim_company` (wait=True)
  - `dim_division` -> `pp_load_stg_to_dim_division` (wait=True)
  - `dim_period` -> `pp_load_stg_to_dim_period` (wait=True)
  - `dim_operating_unit` -> `pp_load_stg_to_dim_operating_unit` (wait=True)
  - `dim_project` -> `pp_load_stg_to_dim_project` (wait=True)
- **Connections:**
  - `gbp-data-pipeline` (ShareableCloud) FabricDataPipelines id=`50db2697-5602-4de2-9834-a8a3ab0f4158`
- **Artifacts in definition:** `EDW_Silver.Warehouse`
- **Variables:** ['v_dim_company_failed_activity', 'v_dim_division_failed_activity', 'v_dim_period_failed_activity', 'v_dim_operating_unit_failed_activity', 'v_dim_project_failed_activity', 'v_dim_job_task_failed_activity', 'v_dim_sale_transfer_failed_activity', 'v_dim_major_minor_failed_activity', 'v_dim_sgm_map_failed_activity', 'v_dim_job_failed_activity', 'v_dim_sale_failed_activity', 'v_dim_lot_failed_activity', 'v_fact_general_ledger_failed_activity', 'v_fact_lot_financials_failed_activity', 'v_failed_activity']
- **Schedule:** off Cron every 15m (India Standard Time; end 2025-07-28)
- **Runs:** 0 tot / 0 ok / 0 fail

### `pp_salesforce_fabric_ingestion`
- **ID:** `944a7184-4d26-4e45-b815-11ac2ee393e3`
- **Activity types:** `{'Lookup': 2, 'ForEach': 1, 'IfCondition': 1, 'Copy': 1, 'Script': 2}`
- **Top-level flow:** Lookup:lkp_table_list -> ForEach:foreach_salesforceobjects
- **Connections:**
  - `Salesforce_UAT` (ShareableCloud) https://greenbrick--uat.sandbox.my.salesforce.com/ id=`37551f20-232c-4133-ae10-9b04df2d6f7f`
- **Artifacts in definition:** `Salesforce_WH.Warehouse`
- **Schedule:** off Cron every 10m (Central Standard Time; end 2029-12-31)
- **Runs:** 0 tot / 0 ok / 0 fail

### `pp_salesforce_fabric_ingestion_bkp1`
- **ID:** `4b00092e-c22d-4de9-871f-3e2e191f9d10`
- **Activity types:** `{'Lookup': 2, 'ForEach': 1, 'IfCondition': 1, 'Copy': 2, 'Script': 3, 'SetVariable': 1}`
- **Top-level flow:** Lookup:lkp_table_list -> ForEach:foreach_salesforceobjects -> Copy:copy_salesforce_fabric_copy1
- **Connections:**
  - `Salesforce_UAT` (ShareableCloud) https://greenbrick--uat.sandbox.my.salesforce.com/ id=`37551f20-232c-4133-ae10-9b04df2d6f7f`
- **Artifacts in definition:** `Salesforce_WH.Warehouse`
- **Variables:** ['v_LastModifiedDate', 'LogId']
- **Schedule:** none
- **Runs:** 0 tot / 0 ok / 0 fail

### `pp_salesforce_fabric_ingestion_prod`
- **ID:** `22a02d16-b512-4f89-91f1-89b046c86028`
- **Activity types:** `{'Lookup': 2, 'ForEach': 1, 'IfCondition': 1, 'Copy': 1, 'Script': 2}`
- **Top-level flow:** Lookup:lkp_table_list -> ForEach:foreach_salesforceobjects
- **Connections:**
  - `Salesforce_Prod` (ShareableCloud) https://greenbrick.my.salesforce.com/ id=`207e8644-adf2-4e53-97d7-b14f9679bce4`
- **Artifacts in definition:** `Salesforce_WH.Warehouse`
- **Schedule:** none
- **Runs:** 331 tot / 329 ok / 2 fail
  - 2026-07-15T17:57:56.6741818 -> 2026-07-15T18:06:15.9933333 | Completed | Manual
  - 2026-07-15T16:57:19.500586 -> 2026-07-15T17:07:16.4033333 | Completed | Manual
  - 2026-07-15T15:57:27.1607656 -> 2026-07-15T16:06:43.5633333 | Completed | Manual
  - 2026-07-15T14:57:16.5099452 -> 2026-07-15T15:06:38.8933333 | Completed | Manual
  - 2026-07-15T13:57:20.8517583 -> 2026-07-15T14:06:18.1133333 | Completed | Manual

### `pp_salesforce_fabric_ingestion_test`
- **ID:** `362d2c01-61e0-418f-bac0-07386fab47a1`
- **Activity types:** `{'Lookup': 1, 'SetVariable': 4, 'Copy': 2}`
- **Top-level flow:** Lookup:lkp_table_list -> SetVariable:Set variable1 -> SetVariable:Set variable2 -> SetVariable:Set variable3 -> SetVariable:Set variable4 -> Copy:copy_salesforce_fabric_copy1 -> Copy:Copy data1
- **Connections:**
  - `Salesforce_UAT` (ShareableCloud) https://greenbrick--uat.sandbox.my.salesforce.com/ id=`37551f20-232c-4133-ae10-9b04df2d6f7f`
- **Artifacts in definition:** `Salesforce_WH.Warehouse`
- **Variables:** ['v_src_table_name', 'v_tgt_table_name', 'v_tgt_schema_name', 'v_table_fields']
- **Schedule:** none
- **Runs:** 0 tot / 0 ok / 0 fail

### `pp_salesforce_fabric_ingestion_UAT`
- **ID:** `a34cf9d7-effb-44e4-a479-1b0d8b509377`
- **Activity types:** `{'Lookup': 2, 'ForEach': 1, 'IfCondition': 1, 'Copy': 2, 'Script': 2}`
- **Top-level flow:** Lookup:lkp_table_list -> ForEach:foreach_salesforceobjects -> Copy:copy_salesforce_fabric_copy1
- **Connections:**
  - `Salesforce_UAT` (ShareableCloud) https://greenbrick--uat.sandbox.my.salesforce.com/ id=`37551f20-232c-4133-ae10-9b04df2d6f7f`
- **Artifacts in definition:** `Salesforce_WH_UAT.Warehouse`, `Salesforce_WH.Warehouse`
- **Schedule:** none
- **Runs:** 1 tot / 1 ok / 0 fail
  - 2026-06-16T13:40:54.744415 -> 2026-06-16T13:54:00.3871687 | Completed | Manual

### `pp_salesforce_orchestrator_prod`
- **ID:** `2ff24d32-6afa-43c0-842c-55eef794cd77`
- **Activity types:** `{'InvokePipeline': 3}`
- **Top-level flow:** InvokePipeline:fabric_to_salesforce -> InvokePipeline:salesforce_to_fabric -> InvokePipeline:load_views_to_csv
- **Invokes:**
  - `fabric_to_salesforce` -> `pp_fabric_salesforce_ingestion_prod` (wait=True)
  - `salesforce_to_fabric` -> `pp_salesforce_fabric_ingestion_prod` (wait=True)
  - `load_views_to_csv` -> `pp_load_view_to_csv` (wait=True)
- **Connections:**
  - `gbp-data-pipeline` (ShareableCloud) FabricDataPipelines id=`50db2697-5602-4de2-9834-a8a3ab0f4158`
- **Schedule:** none
- **Runs:** 429 tot / 326 ok / 100 fail / 3 other
  - 2026-07-15T17:48:01.5149629 -> 2026-07-15T18:09:06.3133333 | Completed | Scheduled
  - 2026-07-15T16:48:01.9319075 -> 2026-07-15T17:15:12.88 | Completed | Scheduled
  - 2026-07-15T15:48:01.5759667 -> 2026-07-15T16:15:16.06 | Completed | Scheduled
  - 2026-07-15T14:48:02.136765 -> 2026-07-15T15:13:07.2 | Completed | Scheduled
  - 2026-07-15T13:48:03.0737752 -> 2026-07-15T14:08:45.06 | Completed | Scheduled

### `pp_temp_schema_discovery`
- **ID:** `d30a42ee-ce1a-4176-a46c-db433ea555b8`
- **Activity types:** `{'Copy': 1}`
- **Top-level flow:** Copy:Copy data1
- **Connections:**
  - `Salesforce_Prod` (ShareableCloud) https://greenbrick.my.salesforce.com/ id=`207e8644-adf2-4e53-97d7-b14f9679bce4`
- **Artifacts in definition:** `Salesforce_WH.Warehouse`
- **Schedule:** none
- **Runs:** 2 tot / 2 ok / 0 fail
  - 2026-06-19T04:07:03.0440944 -> 2026-06-19T04:08:04.0577899 | Completed | Manual
  - 2026-06-19T03:28:31.4746739 -> 2026-06-19T03:29:40.368786 | Completed | Manual
