/*
*******************************************************************************************************************************************************************************************************
    OBJECT NAME    : SP_LOAD_DIM_JOB_TASK
    CREATED BY     : Akshaya Dhanraj
    CREATED ON     : 27/05/2025
    PURPOSE        : Stored procedure for loading dimension tables
    INPUT PARAMS   : JobRunId,MaxDate,LoadType
    OUT PARAMS     : BOOLEAN
    EXEC Statement : EXEC dbo.sp_load_dim_job_task(<JobRunId>, <MaxDate>, <LoadType>);
*******************************************************************************************************************************************************************************************************
*/
CREATE           PROCEDURE dbo.sp_load_dim_job_task

    @CreatedBy    VARCHAR(100) = 'GB_user',
    @JobRunId     VARCHAR(100),
    @LoadType     VARCHAR(20) = '',
    @AuditId      VARCHAR(100) = '',
    @OrchestratorAuditId VARCHAR(100) = ''

AS
BEGIN

    -- Declare & Define Last Modified Datetime , Audit Id & Load Type --
    --****************************************************************--
    DECLARE @MaxDateTime VARCHAR(100); 
    DECLARE @pipeline_audit_id VARCHAR(100) = @AuditId;

    IF @AuditId = ''
    BEGIN
        SELECT @AuditId = CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))) ;
    END;

    IF @LoadType = ''
    BEGIN
        SELECT @MaxDateTime = ISNULL(CONVERT(VARCHAR(15), MAX(lastmoddatetime)),'Table is empty') FROM dbo.dim_job_task;
        SELECT @LoadType = CASE WHEN @MaxDateTime = 'Table is empty' THEN 'FULL' ELSE 'INCREMENTAL' END;
    END;
    --****************************************************************--

    -- Audit Variables
    DECLARE @audit_id BIGINT = CAST(@AuditId AS BIGINT);
    DECLARE @orchestrator_audit_id VARCHAR(100) = @OrchestratorAuditId;
    DECLARE @sp_audit_id BIGINT;
    DECLARE @step_audit_id BIGINT;
    DECLARE @total_steps INT = 5;
    DECLARE @current_step INT = 1;
    DECLARE @records_affected BIGINT;
    DECLARE @total_inserted BIGINT = 0;
    DECLARE @total_updated BIGINT = 0;
    DECLARE @total_deleted BIGINT = 0;
    DECLARE @total_record_count BIGINT = 0;

    BEGIN TRY

        DECLARE @end_date DATETIME2(3) = CAST('9999-12-31' AS DATETIME2(3));
        DECLARE @current_datetime DATETIME2(3) = GETDATE();

        -- Start SP Run Audit --
        --*************************--
        EXEC control.sp_audit_start
            @audit_id         = @audit_id,
            @orchestrator_audit_id = @orchestrator_audit_id,
            @pipeline_audit_id = @pipeline_audit_id,
            @audit_type       = 'SP',
            @pipeline_run_id  = @JobRunId,
            @procedure_name   = 'sp_load_dim_job_task',
            @load_type        = @LoadType,
            @max_date_time    = @MaxDateTime,
            @created_by       = @CreatedBy,
            @total_steps      = @total_steps,
            @return_id        = @sp_audit_id OUTPUT;
        --*************************--

        -------------------------
        -- STEP 1: Load PREP_01 --
        -------------------------

        -- Start Step1 Run Audit --
        --*************************--
        SET @current_step = 1;
        EXEC control.sp_audit_start 
            @audit_id         = @audit_id,
            @audit_type       = 'STEP',
            @step_number      = @current_step,
            @step_name        = 'Load PREP_01',
            @step_description = 'Extract and prepare data from source tables',
            @return_id        = @step_audit_id OUTPUT;
        --*************************--
        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Loading PREP_01';
        IF OBJECT_ID('tempdb..#PREP_01_dim_job_task') IS NOT NULL DROP TABLE #PREP_01_dim_job_task;

        SELECT 
            job_task_id
            ,job_id
            ,task_id
            ,task_code
            ,task_name
            ,task_description
            ,task_type
            ,task_status
            ,task_status_descr
            ,baseline_start_date
            ,baseline_end_date
            ,revised_start_date
            ,revised_end_date
            ,actual_start_date
            ,actual_end_date
            ,milestone_key
            ,purchase_order_number
            ,po_id
            ,vendor_name
            ,vendor_aid
            ,is_epo
            ,created
            ,rank
            ,corp_milestone_num
            ,bldr_milestone_num
            ,lastmoddatetime
            INTO #PREP_01_dim_job_task
            FROM (SELECT 
            CONCAT(mjt1.job_id , '_' , mjt1.task_id) AS job_task_id
            ,mjt1.job_id AS job_id 
            ,mjt1.task_id AS task_id
            ,mjt1.acct_code AS task_code
            ,mjt1.task_name AS task_name
            ,mjt1.task_desc AS task_description
            ,mjt1.task_type AS task_type
            ,mjt1.task_status AS task_status
            ,CASE
                WHEN mjt1.task_status = 'D' THEN 'Completed'
                WHEN mjt1.task_status = 'B' THEN 'In Progress'
                WHEN mjt1.task_status = 'A' THEN 'Scheduled'
                WHEN mjt1.task_status = 'C' THEN 'Cancelled'
                WHEN mjt1.task_status = 'E' THEN 'Skipped'
                END AS task_status_descr
            ,mjt1.init_start_date AS baseline_start_date
            ,mjt1.init_end_date AS baseline_end_date
            ,mjt1.adj_start_date AS revised_start_date
            ,mjt1.adj_end_date AS revised_end_date
            ,mjt1.act_start_date AS actual_start_date
            ,mjt1.act_end_date AS actual_end_date
            ,mjt1.mstone_ind AS mstone_ind
            ,mjt1.acct_code AS acct_code
            ,mjt1.mstone_key AS milestone_key
            ,mjt1.po_num AS purchase_order_number
            ,puh.poid AS po_id
            ,ms1.supplier_name AS vendor_name
            ,ms1.alt_supplier_id AS vendor_aid
            ,mjt1.hot_shot_ind AS is_epo
            ,mjt1.created AS created
            ,ROW_NUMBER() OVER (
            PARTITION BY mjt1.job_id, mjt1.po_num, mjt1.acct_code 
            ORDER BY 
                mjt1.job_id, 
                mjt1.po_num, 
                mjt1.acct_code,
                CASE
                    WHEN mjt1.task_status = 'D' THEN 1
                    WHEN mjt1.task_status = 'B' THEN 2
                    WHEN mjt1.task_status = 'A' THEN 3
                    WHEN mjt1.task_status = 'C' THEN 4
                    WHEN mjt1.task_status = 'E' THEN 5
                END,
                mjt1.created DESC
            ) AS rank
            ,CASE WHEN m1.OUnit = 'CORP' THEN m1.Num ELSE NULL END AS corp_milestone_num
            ,CASE WHEN m2.OUnit = p1.ounitcode THEN m2.Num ELSE NULL END AS bldr_milestone_num
            ,(
                    SELECT MAX(v.dt)
                    FROM (VALUES
                            (mjt1.modified),
                            (ISNULL(ms1.modified, CAST('1950-01-01 00:00:00.000' AS datetime2(3))))
                        ) AS v(dt)
                ) AS lastmoddatetime
        FROM BuildPro.dbo.mh4_job_task mjt1 
        INNER JOIN BuildPro.dbo.mh4_job mj1 ON mjt1.job_id = mj1.job_id
        INNER JOIN BuildPro.dbo.mh4_org mo1 ON mj1.org_id = mo1.org_id
        INNER JOIN HBLive.rems.project p1 ON  mo1.org_num = p1.projid
        LEFT JOIN EDW_Silver.dbo.tbl_Milestones m1 ON m1.TaskCode = mjt1.acct_code and m1.OUnit = 'CORP'
        LEFT JOIN EDW_Silver.dbo.tbl_Milestones m2 ON m2.TaskCode = mjt1.acct_code and m2.OUnit = p1.ounitcode
        LEFT JOIN BuildPro.dbo.mh4_supplier ms1 ON mjt1.supplier_id = ms1.supplier_id
        LEFT JOIN HBLive.rems.puheader puh 
            ON puh.ruleid = CASE 
                                WHEN CHARINDEX('_', mjt1.po_num) > 0 
                                THEN LEFT(mjt1.po_num, CHARINDEX('_', mjt1.po_num) - 1)
                            END
            AND puh.pono = CASE 
                            WHEN CHARINDEX('_', mjt1.po_num) > 0 
                            THEN SUBSTRING(mjt1.po_num, CHARINDEX('_', mjt1.po_num) + 1, LEN(mjt1.po_num))
                        END
        ) djt1
        WHERE 
            CASE WHEN @LoadType = 'FULL' THEN 1
                 WHEN @LoadType = 'INCREMENTAL' 
                 AND CONVERT(VARCHAR(23), lastmoddatetime) > @MaxDateTime THEN 1
                ELSE 0
            END = 1;

        -- End Step1 Run Audit --
        --*************************--
        SET @records_affected = @@ROWCOUNT;
        EXEC control.sp_audit_end 
            @audit_type        = 'STEP',
            @audit_id          = @step_audit_id,
            @status            = 'SUCCESS',
            @records_affected  = @records_affected;
        --*************************--

        SET @current_step += 1;

        -------------------------
        -- STEP 2: Load PREP_02 --
        -------------------------

        -- Start Step2 Run Audit --
        --*************************--
        EXEC control.sp_audit_start 
            @audit_id         = @audit_id,
            @audit_type       = 'STEP',
            @step_number      = @current_step,
            @step_name        = 'Load PREP_02',
            @step_description = 'Generate hash keys and prepare final dataset',
            @return_id        = @step_audit_id OUTPUT;
        --*************************--

        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Loading PREP_02';
        IF OBJECT_ID('tempdb..#PREP_02_dim_job_task') IS NOT NULL DROP TABLE #PREP_02_dim_job_task;

        SELECT
            src.*,
            CONVERT(VARCHAR(64), HASHBYTES('SHA2_256',
                    CONCAT(
                        ISNULL(TRIM(CAST(src.job_id AS VARCHAR)), ''),'~',
                        ISNULL(TRIM(CAST(src.task_id AS VARCHAR)), ''),'~',
                        ISNULL(TRIM(src.task_code), ''),'~',
                        ISNULL(TRIM(src.task_name), ''),'~',
                        ISNULL(TRIM(src.task_description), ''),'~',
                        ISNULL(TRIM(src.task_type), ''),'~',
                        ISNULL(TRIM(src.task_status), ''),'~',
                        ISNULL(TRIM(src.task_status_descr), ''),'~',
                        ISNULL(TRIM(CAST(src.baseline_start_date AS VARCHAR)), ''),'~',
                        ISNULL(TRIM(CAST(src.baseline_end_date AS VARCHAR)), ''),'~',
                        ISNULL(TRIM(CAST(src.revised_start_date AS VARCHAR)), ''),'~',
                        ISNULL(TRIM(CAST(src.revised_end_date AS VARCHAR)), ''),'~',
                        ISNULL(TRIM(CAST(src.actual_start_date AS VARCHAR)), ''),'~',
                        ISNULL(TRIM(CAST(src.actual_end_date AS VARCHAR)), ''),'~',
                        ISNULL(TRIM(CAST(src.milestone_key AS VARCHAR)), ''),'~',
                        ISNULL(TRIM(src.purchase_order_number), ''),'~',
                        ISNULL(TRIM(CAST(src.po_id AS VARCHAR)), ''),'~',
                        ISNULL(TRIM(src.vendor_name), ''),'~',
                        ISNULL(TRIM(src.vendor_aid), ''),'~',
                        ISNULL(TRIM(src.is_epo), ''),'~',
                        ISNULL(TRIM(CAST(src.created AS VARCHAR)), ''),'~',
                        ISNULL(TRIM(CAST(src.rank AS VARCHAR)), ''),'~',
                        ISNULL(TRIM(CAST(src.corp_milestone_num AS VARCHAR)), ''),'~',
                        ISNULL(TRIM(CAST(src.bldr_milestone_num AS VARCHAR)), '')
                    )
                ), 
            2) AS record_hash_key,
            @current_datetime AS effective_start_date,
            @current_datetime AS created_date,
            @CreatedBy AS created_by,
            @JobRunId AS created_job_run_id
        INTO #PREP_02_dim_job_task    
        FROM #PREP_01_dim_job_task src
        LEFT JOIN dbo.dim_job_task tgt
          ON src.job_task_id = tgt.job_task_id AND tgt.is_active = 'Y';

        -- End Step2 Run Audit --
        --*************************--
        SET @records_affected = @@ROWCOUNT;
        EXEC control.sp_audit_end 
            @audit_type        = 'STEP',
            @audit_id          = @step_audit_id,
            @status            = 'SUCCESS',
            @records_affected  = @records_affected;
        --*************************--

        SET @current_step += 1;

        -------------------------------------------------
        -- STEP 3: Update End Date for Deleted Records --
        -------------------------------------------------

        -- Start Step3 Run Audit --
        --*************************--

        EXEC control.sp_audit_start 
            @audit_id         = @audit_id,
            @audit_type       = 'STEP',
            @step_number      = @current_step,
            @step_name        = 'Update Deleted Records',
            @step_description = 'Mark deleted records as inactive',
            @return_id        = @step_audit_id OUTPUT;
        --*************************--

        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Update End Date for Deleted Records';

        UPDATE tgt 
        SET tgt.is_active = 'N',
            tgt.is_deleted = 'Y',
            tgt.effective_end_date = @current_datetime
        FROM EDW_Silver.dbo.dim_job_task tgt
        LEFT JOIN BuildPro.dbo.mh4_job_task src
        ON tgt.job_task_id = CONCAT(src.job_id , '_' , src.task_id)
        WHERE CONCAT(src.job_id , '_' , src.task_id) IS NULL AND tgt.is_active = 'Y';

        -- End Step3 Run Audit --
        --*************************--
        SET @records_affected = @@ROWCOUNT;
        SET @total_deleted = @records_affected;
        EXEC control.sp_audit_end 
            @audit_type        = 'STEP',
            @audit_id          = @step_audit_id,
            @status            = 'SUCCESS',
            @records_affected  = @records_affected;
        --*************************--

        SET @current_step += 1;

        -------------------------------------------------
        -- STEP 4: Update End Date for Changed Records --
        -------------------------------------------------

        -- Start Step4 Run Audit --
        --*************************--
        EXEC control.sp_audit_start 
            @audit_id         = @audit_id,
            @audit_type       = 'STEP',
            @step_number      = @current_step,
            @step_name        = 'Update Changed Records',
            @step_description = 'End-date changed records for SCD Type 2',
            @return_id        = @step_audit_id OUTPUT;
        --*************************--

        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Update End Date for Changed Records';

        UPDATE tgt
        SET tgt.effective_end_date = @current_datetime,
            tgt.is_active = 'N'
        FROM dbo.dim_job_task tgt
        JOIN #PREP_02_dim_job_task src
          ON tgt.job_task_id = src.job_task_id
         AND tgt.is_active = 'Y'
        WHERE tgt.record_hash_key <> src.record_hash_key;

        -- End Step4 Run Audit --
        --*************************--
        SET @records_affected = @@ROWCOUNT;
        SET @total_updated = @records_affected;
        EXEC control.sp_audit_end 
            @audit_type        = 'STEP',
            @audit_id          = @step_audit_id,
            @status            = 'SUCCESS',
            @records_affected  = @records_affected;
        --*************************--

        SET @current_step += 1;

        ---------------------------------------
        --- STEP 5. Insert new/changed rows ---
        ---------------------------------------

        -- Start Step5 Run Audit --
        --*************************--

        EXEC control.sp_audit_start 
            @audit_id         = @audit_id,
            @audit_type       = 'STEP',
            @step_number      = @current_step,
            @step_name        = 'Insert New/Changed Records',
            @step_description = 'Insert new and changed records into target table',
            @return_id        = @step_audit_id OUTPUT;
        --*************************--

        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Insert New/Changed Records';

        INSERT INTO dbo.dim_job_task (
            job_task_guid,
            job_task_id,
            job_id,
            task_id,
            task_code,
            task_name,
            task_description,
            task_type,
            task_status,
            task_status_descr,
            baseline_start_date,
            baseline_end_date,
            revised_start_date,
            revised_end_date,
            actual_start_date,
            actual_end_date,
            milestone_key,
            purchase_order_number,
            po_id,
            vendor_name,
            vendor_aid,
            is_epo,
            created,
            rank,
            corp_milestone_num,
            bldr_milestone_num,
            lastmoddatetime,
            effective_start_date, effective_end_date, is_active, is_deleted,
            created_date, created_by, created_job_run_id, record_hash_key
        )
        SELECT
            CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))),
            src.job_task_id,
            src.job_id,
            src.task_id,
            src.task_code,
            src.task_name,
            src.task_description,
            src.task_type,
            src.task_status,
            src.task_status_descr,
            src.baseline_start_date,
            src.baseline_end_date,
            src.revised_start_date,
            src.revised_end_date,
            src.actual_start_date,
            src.actual_end_date,
            src.milestone_key,
            src.purchase_order_number,
            src.po_id,
            src.vendor_name,
            src.vendor_aid,
            src.is_epo,
            src.created,
            src.rank,
            src.corp_milestone_num,
            src.bldr_milestone_num,
            src.lastmoddatetime,
            src.effective_start_date, @end_date, 'Y', 'N',
            src.created_date, src.created_by, src.created_job_run_id, src.record_hash_key
        FROM #PREP_02_dim_job_task src
        LEFT JOIN dbo.dim_job_task tgt
          ON src.job_task_id = tgt.job_task_id AND tgt.is_active = 'Y'
        WHERE tgt.job_task_id IS NULL OR tgt.record_hash_key <> src.record_hash_key;

        SET @records_affected = @@ROWCOUNT;
        SET @total_inserted = @records_affected;

        -- End Step5 Run Audit --
        --*************************--
        EXEC control.sp_audit_end 
            @audit_type        = 'STEP',
            @audit_id          = @step_audit_id,
            @status            = 'SUCCESS',
            @records_affected  = @records_affected;
        --*************************--

        SELECT @total_record_count = count(job_task_guid) FROM EDW_Silver.dbo.dim_job_task WHERE is_active = 'Y';

        -- End SP Run Audit --
        --*************************--
        EXEC control.sp_audit_end
            @audit_type         = 'SP',
            @audit_id           = @audit_id,
            @status             = 'SUCCESS',
            @completed_steps    = @total_steps,
            @records_inserted   = @total_inserted,
            @records_updated    = @total_updated,
            @records_deleted    = @total_deleted,
            @total_record_count = @total_record_count;
        --*************************--

    END TRY
    BEGIN CATCH
        DECLARE @full_error_message VARCHAR(4000) = 'Error at Step ' + CAST(@current_step AS VARCHAR) + ': ' + ERROR_MESSAGE();
        DECLARE @completed_steps_final INT = @current_step - 1;

        IF @step_audit_id IS NOT NULL
        BEGIN
            EXEC control.sp_audit_end 
                @audit_type      = 'STEP',
                @audit_id        = @step_audit_id,
                @status          = 'FAILED',
                @error_message   = @full_error_message;
        END

        EXEC control.sp_audit_end
            @audit_type         = 'SP',
            @audit_id           = @audit_id,
            @status             = 'FAILED',
            @completed_steps    = @completed_steps_final,
            @failed_step        = @current_step,
            @error_message      = @full_error_message;

        THROW;
    END CATCH
END;