/*
*******************************************************************************************************************************************************************************************************
    OBJECT NAME    : SP_LOAD_DIM_JOB
    CREATED BY     : Akshaya Dhanraj
    CREATED ON     : 27/05/2025
    PURPOSE        : Stored procedure for loading dimension tables
    INPUT PARAMS   : JobRunId,MaxDate,LoadType
    OUT PARAMS     : BOOLEAN
    EXEC Statement : EXEC transform.sp_load_job(<JobRunId>, <MaxDate>, <LoadType>);
*******************************************************************************************************************************************************************************************************
*/
CREATE       PROCEDURE transform.sp_load_job

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
        SELECT @MaxDateTime = ISNULL(CONVERT(VARCHAR(15), MAX(lastmoddatetime)),'Table is empty') FROM transform.job;
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
            @procedure_name   = 'sp_load_job',
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
        IF OBJECT_ID('tempdb..#PREP_01_dim_job') IS NOT NULL DROP TABLE #PREP_01_dim_job;

        WITH CTE_dim_job_task AS (

        SELECT 
            djt1.job_id,
            MAX(CASE WHEN djt1.task_code = '001JSTRT' THEN djt1.actual_end_date END) AS start_task_actual_end,
            MAX(CASE WHEN djt1.task_code = '001JSTRT' THEN djt1.revised_end_date END) AS start_task_revised_end,
            MAX(CASE WHEN djt1.task_code = '009QIC' THEN djt1.actual_end_date END) AS completion_task_actual_end,
            MAX(CASE WHEN djt1.task_code = '009QIC' THEN djt1.revised_end_date END) AS completion_task_revised_end,
            MAX(djt1.corp_milestone_num) AS current_corp_milestone,
            MAX(djt1.bldr_milestone_num) AS current_bldr_milestone
        FROM transform.job_task djt1 WHERE djt1.is_active = 'Y' 
            AND djt1.actual_end_date IS NOT NULL AND djt1.rank = 1 
        GROUP BY djt1.job_id
        ),
        CTE_job_history AS (
            SELECT 
                jh.job_id,
                MIN(jh.created) AS revert_to_dirt_date
            FROM BuildPro.dbo.mh4_job_history jh
            JOIN CTE_dim_job_task djt ON djt.job_id = jh.job_id
            WHERE jh.status = 'Z' 
            AND djt.start_task_actual_end IS NOT NULL
            GROUP BY jh.job_id
        ),
        dim_job AS ( SELECT 
            jp1.projid AS project_id,
            mj1.job_id AS job_id,
            jp1.projid + '_' + jp1.phase AS lot_id,
            jp1.phase AS lot_number,
            mj1.plan_name AS schedule_code,
            CASE 
                WHEN djt1.completion_task_actual_end IS NOT NULL AND mj1.status = 'A' THEN 'Active - Completed'
                WHEN djt1.start_task_actual_end IS NOT NULL AND mj1.status = 'A' THEN 'Active - Under Construction'
                WHEN djt1.start_task_actual_end IS NULL AND mj1.status = 'A' THEN 'Active - Pending Start'
                WHEN mj1.status = 'C' THEN 'Completed' 
                WHEN mj1.status = 'H' THEN 'Hold' 
                WHEN mj1.status = 'W' THEN 'Warranty'
                WHEN djt1.start_task_actual_end IS NOT NULL AND mj1.status = 'Z' THEN 'Deactivated'
                ELSE mj1.status
            END AS job_status,
            mu1.first_name + ' ' + mu1.last_name AS construction_manager,
            COALESCE(djt1.start_task_revised_end, jp1.startdate) AS planned_start_date,
            CASE 
                    WHEN jp1.userdeflog##8 = 1 THEN jp1.startdate
                    WHEN jp1.startdate < '2018-02-01' THEN jp1.startdate
                    ELSE djt1.start_task_actual_end
            END AS start_date,
            djt1.completion_task_revised_end AS planned_complete_date,
            COALESCE(jp1.userdefdate##8, djt1.completion_task_actual_end) AS complete_date,
            jhr1.revert_to_dirt_date,
            djt1.current_corp_milestone,
            djt1.current_bldr_milestone,
            CASE WHEN mj1.status <> 'Z' THEN 1 ELSE 0 END AS job_active,
            (
                SELECT MAX(v.dt)
                FROM (VALUES
                    (jp1.lastmoddatetime),
                    (CAST(CONVERT(CHAR(8), mj1.modified, 112) AS VARCHAR) + '.' +
                        REPLACE(CONVERT(CHAR(8), mj1.modified, 108), ':', '')),
                    (CAST(CONVERT(CHAR(8), mu1.modified, 112) AS VARCHAR) + '.' +
                        REPLACE(CONVERT(CHAR(8), mu1.modified, 108), ':', ''))
                ) AS v(dt)
            ) AS lastmoddatetime

            FROM HBLive.rems.jobphase jp1
            INNER JOIN BuildPro.dbo.mh4_org mo1 ON mo1.org_num = jp1.projid
            INNER JOIN BuildPro.dbo.mh4_job mj1 ON mj1.org_id = mo1.org_id 
                                            AND mj1.legal_desc1 = jp1.phase
            LEFT JOIN BuildPro.dbo.mh4_user mu1 ON mu1.user_id = mj1.primary_user_id
            LEFT JOIN CTE_dim_job_task djt1 ON djt1.job_id = mj1.job_id
            LEFT JOIN CTE_job_history jhr1 ON jhr1.job_id = mj1.job_id
        ) 
            SELECT *
            INTO #PREP_01_dim_job
            FROM dim_job dj1
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
        IF OBJECT_ID('tempdb..#PREP_02_dim_job') IS NOT NULL DROP TABLE #PREP_02_dim_job;

        SELECT
            src.*,CONVERT(VARCHAR(64), HASHBYTES('SHA2_256',
            CONCAT(
                ISNULL(TRIM(src.project_id), ''), '~',
                ISNULL(CONVERT(VARCHAR,src.job_id), ''), '~',
                ISNULL(TRIM(src.lot_id), ''), '~',
                ISNULL(CONVERT(VARCHAR,src.lot_number), ''), '~',
                ISNULL(TRIM(src.schedule_code), ''), '~',
                ISNULL(TRIM(src.job_status), ''), '~',
                ISNULL(TRIM(src.construction_manager), ''), '~',
                ISNULL(CAST(src.planned_start_date AS VARCHAR), ''), '~',
                ISNULL(CAST(src.start_date AS VARCHAR), ''), '~',
                ISNULL(CAST(src.planned_complete_date AS VARCHAR), ''), '~',
                ISNULL(CAST(src.complete_date AS VARCHAR), ''), '~',
                ISNULL(CAST(src.revert_to_dirt_date AS VARCHAR), ''), '~',
                ISNULL(CONVERT(VARCHAR, src.current_corp_milestone), ''), '~',
                ISNULL(CONVERT(VARCHAR, src.current_bldr_milestone), ''), '~',
                ISNULL(CONVERT(VARCHAR, src.job_active), '')
                )
            ), 2) AS record_hash_key,
            @current_datetime AS effective_start_date,
            @current_datetime AS created_date,
            @CreatedBy AS created_by,
            @JobRunId AS created_job_run_id
        INTO #PREP_02_dim_job    
        FROM #PREP_01_dim_job src

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
        FROM transform.job tgt
        LEFT JOIN BuildPro.dbo.mh4_job src
        ON tgt.job_id = src.job_id
        WHERE src.job_id IS NULL AND tgt.is_active = 'Y';

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
        FROM transform.job tgt
        JOIN #PREP_02_dim_job src
          ON tgt.job_id = src.job_id
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

        INSERT INTO transform.job (
            job_guid,
            project_id,
            job_id,
            lot_id,
            lot_number,
            schedule_code,
            job_status,
            construction_manager,
            planned_start_date,
            start_date,
            planned_complete_date,
            complete_date,
            revert_to_dirt_date,
            current_corp_milestone,
            current_bldr_milestone,
            job_active,
            lastmoddatetime,
            effective_start_date, effective_end_date, is_active, is_deleted,
            created_date, created_by, created_job_run_id, record_hash_key
        )
        SELECT
            CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))),
            src.project_id,
            src.job_id,
            src.lot_id,
            src.lot_number,
            src.schedule_code,
            src.job_status,
            src.construction_manager,
            src.planned_start_date,
            src.start_date,
            src.planned_complete_date,
            src.complete_date,
            src.revert_to_dirt_date,
            src.current_corp_milestone,
            src.current_bldr_milestone,
            src.job_active,
            src.lastmoddatetime,
            src.effective_start_date, @end_date, 'Y', 'N',
            src.created_date, src.created_by, src.created_job_run_id, src.record_hash_key
        FROM #PREP_02_dim_job src
        LEFT JOIN transform.job tgt
          ON src.job_id = tgt.job_id AND tgt.is_active = 'Y'
        WHERE tgt.job_id IS NULL OR tgt.record_hash_key <> src.record_hash_key;

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

        SELECT @total_record_count = count(job_guid) FROM transform.job WHERE is_active = 'Y';

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
