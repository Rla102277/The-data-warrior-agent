/*
  wh_stage bootstrap (Foundation Development workspace)
  Endpoint: cx2knzbh2yrejngvheequwseqy-mqufaqgon22utad7n56bdunt4e.datawarehouse.fabric.microsoft.com
  Database: wh_stage

  Run order (after az login refreshes MFA):
    1. This file (schema + audit tables)
    2. automation/sql/stage_load_config.sql (config table + seed)
    3. Copy the 21 sp_load_* procs from EDW_Silver:
         SELECT m.definition FROM EDW_Silver.sys.sql_modules m
         JOIN EDW_Silver.sys.objects o ON m.object_id = o.object_id
         WHERE o.name LIKE 'sp_load%';
       Review each for cross-database references before creating in wh_stage.
    4. Copy exact DDL for control.audit_sp_control / audit_pipeline_control /
       audit_step_control from EDW_Silver (procs write to them); the
       audit_orchestrator_control below matches the columns used by the
       live orchestrator INSERT / UPDATE statements (confirmed from its
       definition) and may need widening to match prod exactly.

  Example connection:
    TOKEN=$(az account get-access-token --resource https://database.windows.net/ --query accessToken -o tsv)
    sqlcmd -S <endpoint> -d wh_stage -G -P "$TOKEN" -i automation/sql/wh_stage_setup.sql
*/

CREATE SCHEMA control;
GO

CREATE TABLE control.audit_orchestrator_control
(
    orchestrator_audit_id  BIGINT        NOT NULL,
    pipeline_name          VARCHAR(200)  NOT NULL,
    pipeline_run_id        VARCHAR(64)   NOT NULL,
    start_time             DATETIME2(0)  NOT NULL,
    end_time               DATETIME2(0)  NULL,
    failed_activity_name   VARCHAR(1000) NULL,
    run_status             VARCHAR(20)   NOT NULL
);
GO
