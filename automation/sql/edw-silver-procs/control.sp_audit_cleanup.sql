CREATE PROCEDURE [control].[sp_audit_cleanup]
AS
BEGIN

    DECLARE @cutoff_date DATETIME2(0) = DATEADD(DAY, -90, CAST(GETDATE() AS DATE));

    IF OBJECT_ID('tempdb..#OrchestratorIds') IS NOT NULL DROP TABLE #OrchestratorIds;
    SELECT 
	orchestrator_audit_id as id
    INTO #OrchestratorIds
    FROM [EDW_Silver].[control].[audit_orchestrator_control]
    WHERE start_time < @cutoff_date;

    IF OBJECT_ID('tempdb..#SpAuditIds') IS NOT NULL DROP TABLE #SpAuditIds;
    SELECT sp_audit_id as id
    INTO #SpAuditIds
    FROM [EDW_Silver].[control].[audit_sp_control]
    WHERE orchestrator_audit_id IN (SELECT id FROM #OrchestratorIds);

    INSERT INTO #SpAuditIds
    SELECT sp_audit_id as id
    FROM [EDW_Silver].[control].[audit_sp_control]
    WHERE (orchestrator_audit_id IS NULL OR orchestrator_audit_id = '')
    AND start_time < @cutoff_date;

    IF OBJECT_ID('tempdb..#PipelineAuditIds') IS NOT NULL DROP TABLE #PipelineAuditIds;
    SELECT pipeline_audit_id as id
    INTO #PipelineAuditIds
    FROM [EDW_Silver].[control].[audit_pipeline_control]
    WHERE orchestrator_audit_id IN (SELECT id FROM #OrchestratorIds);

    INSERT INTO #PipelineAuditIds
    SELECT pipeline_audit_id as id
    FROM [EDW_Silver].[control].[audit_pipeline_control]
    WHERE (orchestrator_audit_id IS NULL OR orchestrator_audit_id = '')
	AND start_time < @cutoff_date;

    DELETE FROM [EDW_Silver].[control].[audit_step_control]
    WHERE sp_audit_id IN (SELECT id FROM #SpAuditIds);

    DELETE FROM [EDW_Silver].[control].[audit_sp_control]
    WHERE sp_audit_id IN (SELECT id FROM #SpAuditIds);

    DELETE FROM [EDW_Silver].[control].[audit_pipeline_control]
    WHERE pipeline_audit_id IN (SELECT id FROM #PipelineAuditIds);

    DELETE FROM [EDW_Silver].[control].[audit_orchestrator_control]
    WHERE orchestrator_audit_id IN (SELECT id FROM #OrchestratorIds);

    IF OBJECT_ID('tempdb..#OrchestratorIds') IS NOT NULL DROP TABLE #OrchestratorIds;
    IF OBJECT_ID('tempdb..#SpAuditIds') IS NOT NULL DROP TABLE #SpAuditIds;
    IF OBJECT_ID('tempdb..#PipelineAuditIds') IS NOT NULL DROP TABLE #PipelineAuditIds;
END;
