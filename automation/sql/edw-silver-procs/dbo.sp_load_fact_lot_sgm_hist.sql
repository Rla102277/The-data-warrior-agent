/*
*******************************************************************************************************************************************************************************************************
    OBJECT NAME    : SP_LOAD_FACT_LOT_SGM_HIST
    CREATED BY     : Kamalesh Radhakrishnan
    CREATED ON     : 11/07/2025
    PURPOSE        : Stored procedure for loading history forfact tables
    INPUT PARAMS   : JobRunId,MaxDateTime,LoadType,AuditId,OrchestratorId
    OUT PARAMS     : BOOLEAN
    EXEC Statement : EXEC dbo.sp_load_fact_lot_sgm_hist(<JobRunId>, <MaxDate>, <LoadType>,<AuditId>,<OrchestratorId>);
*******************************************************************************************************************************************************************************************************
*/

CREATE       PROCEDURE dbo.sp_load_fact_lot_sgm_hist
    @CreatedBy VARCHAR(100) = 'GB_user',
    @JobRunId VARCHAR(100),
    @LoadType VARCHAR(20) = '',
    @AuditId VARCHAR(100) = '',
    @OrchestratorAuditId VARCHAR(100) = ''
AS

BEGIN
    -- Declare & Define variables --
    --****************************************************************--
    DECLARE @current_datetime DATETIME2(3) = GETDATE();
    DECLARE @end_date DATETIME2(3) = CAST('9999-12-31' AS DATETIME2(3));
    DECLARE @MaxDateTime VARCHAR(100);
    DECLARE @pipeline_audit_id VARCHAR(100) = @AuditId;

    IF @AuditId = ''
    BEGIN
        SELECT @AuditId = CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE())));
    END;
    IF @LoadType = ''
    BEGIN
        SELECT @MaxDateTime = ISNULL(CONVERT(VARCHAR(15), MAX(lastmoddatetime)),'Table is empty') FROM EDW_Silver.dbo.fact_lot_sgm_hist;
        SELECT @LoadType = CASE WHEN @MaxDateTime = 'Table is empty' THEN 'FULL' ELSE 'INCREMENTAL' END;
    END;

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


    -- IF @LoadType = 'FULL'
    -- BEGIN
    --     --TRUNCATE TABLE EDW_Silver.dbo.fact_lot_sgm_hist;
    --     --PRINT 'Load type is FULL. EDW_Silver.dbo.fact_lot_sgm_hist table truncated.'
    -- END
    -- ELSE 
    
    --****************************************************************--

    BEGIN TRY

        -- Start SP Run Audit --
        --*************************--
        EXEC control.sp_audit_start
            @audit_id = @audit_id,
            @orchestrator_audit_id = @orchestrator_audit_id,
            @pipeline_audit_id = @pipeline_audit_id,
            @audit_type = 'SP',
            @pipeline_run_id = @JobRunId,
            @procedure_name = 'sp_load_fact_lot_sgm_hist',
            @load_type = @LoadType,
            @max_date_time = @MaxDateTime,
            @created_by = @CreatedBy,
            @total_steps = @total_steps,
            @return_id = @sp_audit_id OUTPUT;
        --*************************--

        --------------------------
        -- STEP 1: Load PREP_01 --
        --------------------------

        -- Start Step1 Run Audit --
        --*************************--
        -- Start Step 1 audit
        SET @current_step = 1;
        EXEC control.sp_audit_start
            @audit_id = @audit_id,
            @audit_type = 'STEP',
            @step_number = @current_step,
            @step_name = 'Load PREP_01',
            @step_description = 'Extract and prepare data from source tables',
            @return_id = @step_audit_id OUTPUT;
        --*************************--

        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Loading PREP_01';
        IF OBJECT_ID('tempdb..#PREP_01_fact_lot_sgm_hist') IS NOT NULL DROP TABLE #PREP_01_fact_lot_sgm_hist;
        SELECT 
            lot_sgm_id,
            lot_id,
            sgm_assumptions_id,
            assumption_id,
            assumption_value_id,
            sgm_category,
            sgm_sub_category,
            sgm_type,
            major_code,
            minor_code,
            trigger1_name,
            trigger1_met,
            trigger2_name,
            trigger2_met,
            calculation_basis,
            gl_actual,
            latest_est_amount,
            amount_assumption,
            use_assumption,
            amount,
            lastmoddatetime
        INTO #PREP_01_fact_lot_sgm_hist
        FROM EDW_Silver.dbo.fact_lot_sgm
        WHERE 
            CASE 
                WHEN @LoadType = 'FULL' THEN 1
                WHEN @LoadType = 'INCREMENTAL' AND CONVERT(VARCHAR(15), lastmoddatetime) > @MaxDateTime THEN 1
                ELSE 0
            END = 1;
        
        -- End Step1 Run Audit --
        --*************************--
        SET @records_affected = @@ROWCOUNT;
        EXEC control.sp_audit_end
            @audit_type = 'STEP',
            @audit_id = @step_audit_id,
            @status = 'SUCCESS',
            @records_affected = @records_affected;
        --*************************--

        SET @current_step += 1;

        --------------------------
        -- STEP 2: Load PREP_02 --
        --------------------------

        -- Start Step2 Run Audit --
        --*************************--
        EXEC control.sp_audit_start
            @audit_id = @audit_id,
            @audit_type = 'STEP',
            @step_number = @current_step,
            @step_name = 'Load PREP_02',
            @step_description = 'Generate hash keys and prepare final dataset',
            @return_id = @step_audit_id OUTPUT;
        --*************************--

        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Loading PREP_02';
        IF OBJECT_ID('tempdb..#PREP_02_fact_lot_sgm_hist') IS NOT NULL DROP TABLE #PREP_02_fact_lot_sgm_hist;
        SELECT 
            src.*,
            @current_datetime AS effective_start_date,
            @current_datetime AS created_date,
            @CreatedBy AS created_by,
            @JobRunId AS created_job_run_id,
            CONVERT(
                VARCHAR(64), 
                HASHBYTES('SHA2_256',
                    CONCAT(
                        ISNULL(TRIM(src.lot_id), '') , '~' ,
                        ISNULL(TRIM(src.sgm_assumptions_id), '') , '~' ,
                        ISNULL(TRIM(src.assumption_id), '') , '~' ,
                        ISNULL(TRIM(src.assumption_value_id), '') , '~' ,
                        ISNULL(TRIM(src.sgm_category), '') , '~' ,
                        ISNULL(TRIM(src.sgm_sub_category), '') , '~' ,
                        ISNULL(TRIM(src.sgm_type), '') , '~' ,
                        ISNULL(TRIM(src.major_code), '') , '~' ,
                        ISNULL(TRIM(src.minor_code), '') , '~' ,
                        ISNULL(TRIM(src.trigger1_name), '') , '~' ,
                        ISNULL(CONVERT(VARCHAR, src.trigger1_met), '') , '~' ,
                        ISNULL(TRIM(src.trigger2_name), '') , '~' ,
                        ISNULL(CONVERT(VARCHAR, src.trigger2_met), '') , '~' ,
                        ISNULL(TRIM(src.calculation_basis), '') , '~' ,
                        ISNULL(CONVERT(VARCHAR, src.gl_actual), '') , '~' ,
                        ISNULL(CONVERT(VARCHAR, src.latest_est_amount), '') , '~' ,
                        ISNULL(CONVERT(VARCHAR, src.amount_assumption), '') , '~' ,
                        ISNULL(CONVERT(VARCHAR, src.use_assumption), '') , '~' ,
                        ISNULL(CONVERT(VARCHAR, src.amount), '')
                    ) 
                ), 
                2
            ) as record_hash_key
        INTO #PREP_02_fact_lot_sgm_hist 
        FROM #PREP_01_fact_lot_sgm_hist as src

        -- End Step2 Run Audit --
        --*************************--
        SET @records_affected = @@ROWCOUNT;
        EXEC control.sp_audit_end
            @audit_type = 'STEP',
            @audit_id = @step_audit_id,
            @status = 'SUCCESS',
            @records_affected = @records_affected;
        --*************************--

        SET @current_step += 1;

        -----------------------------------------
        -- STEP 3: Delete hard-deleted records --
        -----------------------------------------

        -- Start Step3 Run Audit --
        --*************************--
        EXEC control.sp_audit_start
            @audit_id = @audit_id,
            @audit_type = 'STEP',
            @step_number = @current_step,
            @step_name = 'Update hard-deleted records',
            @step_description = 'Update end_date, is_active & is_deleted for hard-deleted records',
            @return_id = @step_audit_id OUTPUT;
        --*************************--

        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Update hard-deleted records';
        UPDATE tgt 
        SET tgt.is_active = 'N',
            tgt.is_deleted = 'Y',
            tgt.effective_end_date = @current_datetime
        FROM EDW_Silver.dbo.fact_lot_sgm_hist tgt
        LEFT JOIN EDW_Silver.dbo.fact_lot_sgm src ON tgt.lot_sgm_id = src.lot_sgm_id
        WHERE src.lot_sgm_id IS NULL AND tgt.is_active = 'Y';

        -- End Step3 Run Audit --
        --*************************--
        SET @records_affected = @@ROWCOUNT;
        SET @total_deleted = @records_affected;
        EXEC control.sp_audit_end
            @audit_type = 'STEP',
            @audit_id = @step_audit_id,
            @status = 'SUCCESS',
            @records_affected = @records_affected;
        --*************************--

        SET @current_step += 1;

        ------------------------------------
        -- STEP 4: Delete updated records --
        ------------------------------------

        -- Start Step4 Run Audit --
        --*************************--
        EXEC control.sp_audit_start
            @audit_id = @audit_id,
            @audit_type = 'STEP',
            @step_number = @current_step,
            @step_name = 'Update updated records',
            @step_description = 'Update end_date & is_active for updated records',
            @return_id = @step_audit_id OUTPUT;
        --*************************--

        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Update updated records';
        UPDATE tgt
        SET tgt.effective_end_date = @current_datetime,
            tgt.is_active = 'N'
        FROM EDW_Silver.dbo.fact_lot_sgm_hist tgt
        JOIN #PREP_02_fact_lot_sgm_hist src
            ON tgt.lot_sgm_id = src.lot_sgm_id
            AND tgt.is_active = 'Y'
        WHERE tgt.record_hash_key <> src.record_hash_key;

        -- End Step4 Run Audit --
        --*************************--
        SET @records_affected = @@ROWCOUNT;
        SET @total_updated = @records_affected;
        EXEC control.sp_audit_end
            @audit_type = 'STEP',
            @audit_id = @step_audit_id,
            @status = 'SUCCESS',
            @records_affected = @records_affected;
        --*************************--
 
        SET @current_step += 1;

        ------------------------------------------
        --- STEP 5: Insert New/Changed records ---
        ------------------------------------------

        -- Start Step5 Run Audit --
        --*************************--
        EXEC control.sp_audit_start
            @audit_id = @audit_id,
            @audit_type = 'STEP',
            @step_number = @current_step,
            @step_name = 'Insert New/Changed Records',
            @step_description = 'Insert new and changed records into target table',
            @return_id = @step_audit_id OUTPUT;
        --*************************--

        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Insert New/Changed Records';
        INSERT INTO EDW_Silver.dbo.fact_lot_sgm_hist (
            lot_sgm_hist_guid, lot_sgm_id, lot_id, sgm_assumptions_id, assumption_id, assumption_value_id, sgm_category, sgm_sub_category,
            sgm_type, major_code, minor_code, trigger1_name, trigger1_met, trigger2_name, trigger2_met, calculation_basis, gl_actual,
            latest_est_amount, amount_assumption, use_assumption, amount, lastmoddatetime, effective_start_date, 
            effective_end_date, is_active, is_deleted, created_date, record_hash_key, created_by, created_job_run_id
        )
        SELECT
            CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))) AS lot_sgm_hist_guid,
            src.lot_sgm_id,
            src.lot_id,
            src.sgm_assumptions_id,
            src.assumption_id,
            src.assumption_value_id,
            src.sgm_category,
            src.sgm_sub_category,
            src.sgm_type,
            src.major_code,
            src.minor_code,
            src.trigger1_name,
            src.trigger1_met,
            src.trigger2_name,
            src.trigger2_met,
            src.calculation_basis,
            src.gl_actual,
            src.latest_est_amount,
            src.amount_assumption,
            src.use_assumption,
            src.amount,
            src.lastmoddatetime,
            src.effective_start_date,
            @end_date,
            'Y',
            'N',
            src.created_date,
            src.record_hash_key,
            src.created_by,
            src.created_job_run_id
        FROM #PREP_02_fact_lot_sgm_hist src
        LEFT JOIN EDW_Silver.dbo.fact_lot_sgm_hist tgt
            ON src.lot_sgm_id = tgt.lot_sgm_id 
                AND tgt.is_active = 'Y'
        WHERE 
        tgt.lot_sgm_id IS NULL 
        OR tgt.record_hash_key <> src.record_hash_key;
 
        -- End Step5 Run Audit --
        --*************************--
        SET @records_affected = @@ROWCOUNT;
        SET @total_inserted = @records_affected;
        EXEC control.sp_audit_end
            @audit_type = 'STEP',
            @audit_id = @step_audit_id,
            @status = 'SUCCESS',
            @records_affected = @records_affected;
        --*************************--

        SELECT @total_record_count = count(lot_sgm_hist_guid) FROM EDW_Silver.dbo.fact_lot_sgm_hist WHERE is_active = 'Y';

        -- End SP Run Audit --
        --*************************--
        EXEC control.sp_audit_end
            @audit_type = 'SP',
            @audit_id = @audit_id,
            @status = 'SUCCESS',
            @completed_steps = @total_steps,
            @records_inserted = @total_inserted,
            @records_updated = @total_updated,
            @records_deleted = @total_deleted,
            @total_record_count = @total_record_count;
        --*************************--

    END TRY
    BEGIN CATCH
        DECLARE @full_error_message VARCHAR(4000) = 'Error at Step ' + CAST(@current_step AS VARCHAR) + ': ' + ERROR_MESSAGE();
        DECLARE @completed_steps_final INT = @current_step - 1; 

        IF @step_audit_id IS NOT NULL
        BEGIN
            EXEC control.sp_audit_end 
                @audit_type = 'STEP',
                @audit_id = @step_audit_id,
                @status = 'FAILED',
                @error_message = @full_error_message;
        END

        EXEC control.sp_audit_end
            @audit_type = 'SP',
            @audit_id = @audit_id,
            @status = 'FAILED',
            @completed_steps = @completed_steps_final,
            @failed_step = @current_step,
            @error_message = @full_error_message;

        THROW;
    END CATCH
END;