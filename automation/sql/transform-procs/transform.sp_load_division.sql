/*
*******************************************************************************************************************************************************************************************************
    OBJECT NAME    : SP_LOAD_DIM_DIVISION
    CREATED BY     : Kamalesh Radhakrishnan
    CREATED ON     : 02/06/2025
    PURPOSE        : Stored procedure for loading dimension tables
    INPUT PARAMS   : JobRunId,MaxDateTime,LoadType,AuditId
    OUT PARAMS     : BOOLEAN
    EXEC Statement : EXEC transform.sp_load_division(<JobRunId>, <MaxDate>, <LoadType>, <AuditId>);
*******************************************************************************************************************************************************************************************************
*/

CREATE         PROCEDURE transform.sp_load_division
    @CreatedBy      VARCHAR(100) = 'GB_user',
    @JobRunId       VARCHAR(100),
    @LoadType       VARCHAR(20) = '',
    @AuditId        VARCHAR(100) = '',
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
        SELECT @MaxDateTime = ISNULL(CONVERT(VARCHAR(15), MAX(lastmoddatetime)),'Table is empty') FROM transform.division;
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
            @audit_id = @audit_id,
            @orchestrator_audit_id = @orchestrator_audit_id,
            @pipeline_audit_id = @pipeline_audit_id,
            @audit_type = 'SP',
            @pipeline_run_id = @JobRunId,
            @procedure_name = 'sp_load_division',
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
        IF OBJECT_ID('tempdb..#PREP_01_dim_division') IS NOT NULL DROP TABLE #PREP_01_dim_division;
        
        SELECT
            d.compcode as company_code,
            CONCAT(d.compcode,'_',d.divcode) as division_id,
            d.divcode as division_code,
            d.name as name,
            d.short as short_code,
            d.subcode as subcode,
            d.current_status as status,
            COALESCE(d.lastmoddatetime,19500101.000000) as lastmoddatetime
        INTO #PREP_01_dim_division
        FROM HBLive.rems.division d
        WHERE 
            CASE 
                WHEN @LoadType = 'FULL' THEN 1
                WHEN @LoadType = 'INCREMENTAL' AND CONVERT(VARCHAR(15), COALESCE(d.lastmoddatetime,19500101.000000)) > @MaxDateTime THEN 1
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

        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Loading PREP_01';
        IF OBJECT_ID('tempdb..#PREP_02_dim_division') IS NOT NULL DROP TABLE #PREP_02_dim_division;
        SELECT 
            src.*,
            CONVERT(
                VARCHAR(64), 
                HASHBYTES('SHA2_256',
                    CONCAT(
                        ISNULL(TRIM(src.company_code), ''),'~',
                        ISNULL(TRIM(src.division_code), ''),'~',
                        ISNULL(TRIM(src.name), ''),'~',
                        ISNULL(TRIM(src.short_code), ''),'~',
                        ISNULL(TRIM(src.subcode), ''),'~',
                        ISNULL(TRIM(src.status), '')
                    ) 
                ), 
                2
            ) as record_hash_key,
            @current_datetime AS effective_start_date,
            @current_datetime AS created_date,
            @CreatedBy AS created_by,
            @JobRunId AS created_job_run_id
        INTO #PREP_02_dim_division
        FROM #PREP_01_dim_division as src
        LEFT JOIN transform.division tgt
            ON src.division_id = tgt.division_id AND tgt.is_active = 'Y';

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

        -------------------------------------------------
        -- STEP 3: Update End Date for Deleted Records --
        -------------------------------------------------

        -- Start Step3 Run Audit --
        --*************************--
        EXEC control.sp_audit_start 
            @audit_id = @audit_id,
            @audit_type = 'STEP',
            @step_number = @current_step,
            @step_name = 'Update Deleted Records',
            @step_description = 'Mark deleted records as inactive',
            @return_id = @step_audit_id OUTPUT;
        --*************************--

        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Update End Date for Deleted Records';    

        UPDATE tgt 
        SET tgt.is_active = 'N',
            tgt.is_deleted = 'Y',
            tgt.effective_end_date = @current_datetime
        FROM transform.division tgt
        LEFT JOIN HBLive.rems.division src
        ON tgt.division_id = CONCAT(src.compcode,'_',src.divcode)
        WHERE CONCAT(src.compcode,'_',src.divcode) IS NULL AND tgt.is_active = 'Y';

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

        -------------------------------------------------
        -- STEP 4: Update End Date for Changed Records --
        -------------------------------------------------

        -- Start Step4 Run Audit --
        --*************************--
        EXEC control.sp_audit_start 
            @audit_id = @audit_id,
            @audit_type = 'STEP',
            @step_number = @current_step,
            @step_name = 'Update Changed Records',
            @step_description = 'End-date changed records for SCD Type 2',
            @return_id = @step_audit_id OUTPUT;
        --*************************--

        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Update End Date for Changed Records';

        UPDATE tgt
        SET tgt.effective_end_date = @current_datetime,
            tgt.is_active = 'N'
        FROM transform.division tgt
        JOIN #PREP_02_dim_division src
          ON tgt.division_id = src.division_id
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

        ---------------------------------------
        --- STEP 5: Insert new/changed rows ---
        ---------------------------------------

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

        INSERT INTO transform.division (
            division_guid, company_code, division_id, division_code, name, short_code, subcode, status, lastmoddatetime, effective_start_date, 
            effective_end_date, is_active, is_deleted, created_date, record_hash_key, created_by, created_job_run_id
        )
        SELECT
            CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))) AS division_guid,
            src.company_code, 
            src.division_id, 
            src.division_code, 
            src.name, 
            src.short_code, 
            src.subcode, 
            src.status,
            src.lastmoddatetime,
            src.effective_start_date,
            @end_date,
            'Y',
            'N',
            src.created_date,
            src.record_hash_key,
            src.created_by,
            src.created_job_run_id
        FROM #PREP_02_dim_division src
        LEFT JOIN transform.division tgt
            ON src.division_id = tgt.division_id 
                AND tgt.is_active = 'Y'
        WHERE 
        tgt.division_id IS NULL 
        OR tgt.record_hash_key <> src.record_hash_key;

        SET @records_affected = @@ROWCOUNT;
        SET @total_inserted = @records_affected;

        -- End Step5 Run Audit --
        --*************************--
        EXEC control.sp_audit_end 
            @audit_type = 'STEP',
            @audit_id = @step_audit_id,
            @status = 'SUCCESS',
            @records_affected = @records_affected;
        --*************************--

        SELECT @total_record_count = count(division_guid) FROM transform.division WHERE is_active = 'Y';

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
        DECLARE @full_error_message VARCHAR(4000) = 
            'Error at Step ' + CAST(@current_step AS VARCHAR) + ': ' + ERROR_MESSAGE();
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