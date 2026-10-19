/*
*******************************************************************************************************************************************************************************************************
    OBJECT NAME    : SP_LOAD_DIM_COMPANY
    CREATED BY     : Kamalesh Radhakrishnan
    CREATED ON     : 30/05/2025
    PURPOSE        : Stored procedure for loading dimension tables
    INPUT PARAMS   : JobRunId,MaxDateTime,LoadType,AuditId
    OUT PARAMS     : BOOLEAN
    EXEC Statement : EXEC dbo.sp_load_dim_company(<JobRunId>, <MaxDate>, <LoadType>, <AuditId>);
*******************************************************************************************************************************************************************************************************
*/

CREATE       PROCEDURE dbo.sp_load_dim_company
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
        SELECT @MaxDateTime = ISNULL(CONVERT(VARCHAR(15), MAX(lastmoddatetime)),'Table is empty') FROM dbo.dim_company;
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
            @procedure_name = 'sp_load_dim_company',
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
        IF OBJECT_ID('tempdb..#PREP_01_dim_company') IS NOT NULL DROP TABLE #PREP_01_dim_company;
        
        SELECT
            cp1.aid as aid,
            cp1.compcode as company_code,
            cp1.name as name,
            cp1.short as short_code,
            a1.street as street,
            a1.street2 as street2,
            a1.suite as suite,
            a1.postal as zip,
            c1.cityname as city,
            c1.provcode as state,
            cp1.gstregno as gstregno,
            cp1.frozen as frozen,
            (
                SELECT MAX(v.dt)
                FROM (VALUES
                    (cp1.lastmoddatetime),
                    (ISNULL(a1.lastmoddatetime, 19500101.000000)),
                    (ISNULL(c1.lastmoddatetime, 19500101.000000))
                ) AS v(dt)
            ) AS lastmoddatetime
        INTO #PREP_01_dim_company
        FROM HBLive.rems.company cp1
        LEFT JOIN HBLive.rems.address a1 on cp1.aid  = a1.aid
        LEFT JOIN HBLive.rems.city c1 on a1.citycode = c1.citycode
        WHERE 
            CASE 
                WHEN @LoadType = 'FULL' THEN 1
                WHEN @LoadType = 'INCREMENTAL' AND CONVERT(VARCHAR(15), (
                        SELECT MAX(v.dt)
                        FROM (VALUES
                            (cp1.lastmoddatetime),
                            (ISNULL(a1.lastmoddatetime, 19500101.000000)),
                            (ISNULL(c1.lastmoddatetime, 19500101.000000))
                        ) AS v(dt)
                    )) > @MaxDateTime THEN 1
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
        IF OBJECT_ID('tempdb..#PREP_02_dim_company') IS NOT NULL DROP TABLE #PREP_02_dim_company;
        SELECT 
            src.*,
            CONVERT(
                VARCHAR(64), 
                HASHBYTES('SHA2_256',
                    CONCAT(
                        ISNULL(CONVERT(VARCHAR,src.aid), ''),'~',
                        ISNULL(TRIM(src.name), ''),'~',
                        ISNULL(TRIM(src.short_code), ''),'~',
                        ISNULL(TRIM(src.street), ''),'~',
                        ISNULL(TRIM(src.street2), ''),'~',
                        ISNULL(TRIM(src.suite), ''),'~',
                        ISNULL(TRIM(src.zip), ''),'~',
                        ISNULL(TRIM(src.city), ''),'~',
                        ISNULL(TRIM(src.state), ''),'~',
                        ISNULL(TRIM(src.gstregno), ''),'~',
                        ISNULL(CONVERT(VARCHAR,src.frozen), '')
                    ) 
                ), 
                2
            ) as record_hash_key,
            @current_datetime AS effective_start_date,
            @current_datetime AS created_date,
            @CreatedBy AS created_by,
            @JobRunId AS created_job_run_id
        INTO #PREP_02_dim_company 
        FROM #PREP_01_dim_company as src
        LEFT JOIN dbo.dim_company tgt
            ON src.company_code = tgt.company_code AND tgt.is_active = 'Y';

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
        FROM EDW_Silver.dbo.dim_company tgt
        LEFT JOIN HBLive.rems.company src
        ON tgt.company_code = src.compcode
        WHERE src.compcode IS NULL AND tgt.is_active = 'Y';

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
        FROM dbo.dim_company tgt
        JOIN #PREP_02_dim_company src
          ON tgt.company_code = src.company_code
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

        INSERT INTO dbo.dim_company (
            company_guid, aid, company_code, name, short_code, street, street2, suite, zip,
            city, state, gstregno, frozen, lastmoddatetime, effective_start_date, 
            effective_end_date, is_active, is_deleted, created_date, record_hash_key, created_by, created_job_run_id
        )
        SELECT
            CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))) AS company_guid,
            src.aid,
            src.company_code,
            src.name,
            src.short_code,
            src.street,
            src.street2,
            src.suite,
            src.zip,
            src.city,
            src.state,
            src.gstregno,
            src.frozen,
            src.lastmoddatetime,
            src.effective_start_date,
            @end_date,
            'Y',
            'N',
            src.created_date,
            src.record_hash_key,
            src.created_by,
            src.created_job_run_id
        FROM #PREP_02_dim_company src
        LEFT JOIN dbo.dim_company tgt
            ON src.company_code = tgt.company_code 
                AND tgt.is_active = 'Y'
        WHERE 
        tgt.company_code IS NULL 
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

        SELECT @total_record_count = count(company_guid) FROM EDW_Silver.dbo.dim_company WHERE is_active = 'Y';

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