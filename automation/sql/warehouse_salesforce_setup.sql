/*
  warehouse_salesforce seed (Foundation Development)
  Source config: GBP-Enterprise Salesforce_WH.metadata.Ingestion_Config
  Outbound rows must remain IsActive=N until UAT connection is approved.
*/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'metadata')
    EXEC('CREATE SCHEMA metadata');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'logging')
    EXEC('CREATE SCHEMA logging');

IF OBJECT_ID('metadata.Ingestion_Config') IS NOT NULL
    DROP TABLE metadata.Ingestion_Config;

CREATE TABLE metadata.Ingestion_Config
(
    Pipeline_Type        varchar(50)  NOT NULL,
    Pipeline_Name        varchar(100) NOT NULL,
    Source_Schema        varchar(50)  NOT NULL,
    Source_Table_Name    varchar(200) NOT NULL,
    Target_Schema        varchar(50)  NOT NULL,
    Target_Table_Name    varchar(200) NOT NULL,
    Table_Fields         varchar(max) NULL,
    Primary_Key          varchar(200) NULL,
    Join_Definition      varchar(max) NULL,
    Watermark_Fields     varchar(200) NULL,
    IsActive             varchar(10)  NOT NULL,
    Load_Type            varchar(50)  NULL,
    Created_Date         datetime2(6) NULL,
    Modified_Date        datetime2(6) NULL,
    Order_Of_Execution   int          NULL
);

IF OBJECT_ID('logging.Pipeline_Table_Load_Log') IS NOT NULL
    DROP TABLE logging.Pipeline_Table_Load_Log;

CREATE TABLE logging.Pipeline_Table_Load_Log
(
    PipelineRunId     varchar(100) NULL,
    PipelineName      varchar(200) NULL,
    PipelineType      varchar(200) NULL,
    TargetSystem      varchar(200) NULL,
    LoadType          varchar(200) NULL,
    TableName         varchar(200) NULL,
    ActivityName      varchar(200) NULL,
    RunDateTime       datetime2(6) NULL,
    Status            varchar(50)  NULL,
    RowsRead          bigint       NULL,
    RowsWritten       bigint       NULL,
    ErrorMessage      varchar(max) NULL,
    DurationSeconds   int          NULL,
    Notes             varchar(500) NULL
);

-- Rows loaded via pipeline_salesforce_enterprise_copy harvest + pipeline_salesforce_sql_runner inserts.
-- See knowledge/pipelines/salesforce-fd.md
