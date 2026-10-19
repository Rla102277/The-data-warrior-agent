/*
*******************************************************************************************************************************************************************************************************
    OBJECT NAME    : SP_LOAD_DIM_PERIOD
    CREATED BY     : Kamalesh Radhakrishnan
    CREATED ON     : 06/06/2025
    PURPOSE        : Stored procedure for loading dimension tables
    INPUT PARAMS   : JobRunId, AuditId
    OUT PARAMS     : BOOLEAN
    EXEC Statement : EXEC dbo.sp_load_dim_period(<JobRunId>, <AuditId>);
*******************************************************************************************************************************************************************************************************
*/

CREATE       PROCEDURE dbo.sp_load_dim_period
    @CreatedBy      VARCHAR(100) = 'GB_user',
    @JobRunId       VARCHAR(100),
    @LoadType     VARCHAR(20) = '',
    @AuditId        VARCHAR(100) = '',
    @OrchestratorAuditId VARCHAR(100) = ''

AS
BEGIN

    -- Declare & Define Last Modified Datetime , Audit Id & Load Type --
    --****************************************************************--
    --DECLARE @MaxDateTime VARCHAR(100); 
    DECLARE @pipeline_audit_id VARCHAR(100) = @AuditId;
    --DECLARE @AuditId     VARCHAR(100);
    --DECLARE @LoadType     VARCHAR(20);

    IF @AuditId = ''
    BEGIN
        SELECT @AuditId = CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))) ;
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
            @procedure_name = 'sp_load_dim_period',
            @load_type = @LoadType,
            @max_date_time = NULL,
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
        IF OBJECT_ID('tempdb..#PREP_01_dim_period') IS NOT NULL DROP TABLE #PREP_01_dim_period;
        
        SELECT * 
        INTO #PREP_01_dim_period
        FROM (
            SELECT
                CONCAT(compcode, '_', fiscalyear, '_', '1') AS period_id,
                compcode AS company_code,
                fiscalyear AS fiscal_year,
                1 AS period,
                DATEFROMPARTS(CAST(fiscalyear AS INT), 1, 1) AS period_start,
                EOMONTH(DATEFROMPARTS(CAST(fiscalyear AS INT), 1, 1)) AS period_end,
                CASE WHEN isactive##1 = 1 THEN CAST(0 AS SMALLINT) ELSE CAST(1 AS SMALLINT) END AS is_closed
            FROM HBLive.rems.activeper WHERE menucode = 'gl'
            UNION ALL
            SELECT
                CONCAT(compcode, '_', fiscalyear, '_', '2') AS period_id,
                compcode AS company_code,
                fiscalyear AS fiscal_year,
                2 AS period,
                DATEFROMPARTS(CAST(fiscalyear AS INT), 2, 1) AS period_start,
                EOMONTH(DATEFROMPARTS(CAST(fiscalyear AS INT), 2, 1)) AS period_end,
                CASE WHEN isactive##2 = 1 THEN CAST(0 AS SMALLINT) ELSE CAST(1 AS SMALLINT) END AS is_closed
            FROM HBLive.rems.activeper WHERE menucode = 'gl'
            UNION ALL
            SELECT
                CONCAT(compcode, '_', fiscalyear, '_', '3') AS period_id,
                compcode AS company_code,
                fiscalyear AS fiscal_year,
                3 AS period,
                DATEFROMPARTS(CAST(fiscalyear AS INT), 3, 1) AS period_start,
                EOMONTH(DATEFROMPARTS(CAST(fiscalyear AS INT), 3, 1)) AS period_end,
                CASE WHEN isactive##3 = 1 THEN CAST(0 AS SMALLINT) ELSE CAST(1 AS SMALLINT) END AS is_closed
            FROM HBLive.rems.activeper WHERE menucode = 'gl'
            UNION ALL
            SELECT
                CONCAT(compcode, '_', fiscalyear, '_', '4') AS period_id,
                compcode AS company_code,
                fiscalyear AS fiscal_year,
                4 AS period,
                DATEFROMPARTS(CAST(fiscalyear AS INT), 4, 1) AS period_start,
                EOMONTH(DATEFROMPARTS(CAST(fiscalyear AS INT), 4, 1)) AS period_end,
                CASE WHEN isactive##4 = 1 THEN CAST(0 AS SMALLINT) ELSE CAST(1 AS SMALLINT) END AS is_closed
            FROM HBLive.rems.activeper WHERE menucode = 'gl'
            UNION ALL
            SELECT
                CONCAT(compcode, '_', fiscalyear, '_', '5') AS period_id,
                compcode AS company_code,
                fiscalyear AS fiscal_year,
                5 AS period,
                DATEFROMPARTS(CAST(fiscalyear AS INT), 5, 1) AS period_start,
                EOMONTH(DATEFROMPARTS(CAST(fiscalyear AS INT), 5, 1)) AS period_end,
                CASE WHEN isactive##5 = 1 THEN CAST(0 AS SMALLINT) ELSE CAST(1 AS SMALLINT) END AS is_closed
            FROM HBLive.rems.activeper WHERE menucode = 'gl'
            UNION ALL
            SELECT
                CONCAT(compcode, '_', fiscalyear, '_', '6') AS period_id,
                compcode AS company_code,
                fiscalyear AS fiscal_year,
                6 AS period,
                DATEFROMPARTS(CAST(fiscalyear AS INT), 6, 1) AS period_start,
                EOMONTH(DATEFROMPARTS(CAST(fiscalyear AS INT), 6, 1)) AS period_end,
                CASE WHEN isactive##6 = 1 THEN CAST(0 AS SMALLINT) ELSE CAST(1 AS SMALLINT) END AS is_closed
            FROM HBLive.rems.activeper WHERE menucode = 'gl'
            UNION ALL
            SELECT
                CONCAT(compcode, '_', fiscalyear, '_', '7') AS period_id,
                compcode AS company_code,
                fiscalyear AS fiscal_year,
                7 AS period,
                DATEFROMPARTS(CAST(fiscalyear AS INT), 7, 1) AS period_start,
                EOMONTH(DATEFROMPARTS(CAST(fiscalyear AS INT), 7, 1)) AS period_end,
                CASE WHEN isactive##7 = 1 THEN CAST(0 AS SMALLINT) ELSE CAST(1 AS SMALLINT) END AS is_closed
            FROM HBLive.rems.activeper WHERE menucode = 'gl'
            UNION ALL
            SELECT
                CONCAT(compcode, '_', fiscalyear, '_', '8') AS period_id,
                compcode AS company_code,
                fiscalyear AS fiscal_year,
                8 AS period,
                DATEFROMPARTS(CAST(fiscalyear AS INT), 8, 1) AS period_start,
                EOMONTH(DATEFROMPARTS(CAST(fiscalyear AS INT), 8, 1)) AS period_end,
                CASE WHEN isactive##8 = 1 THEN CAST(0 AS SMALLINT) ELSE CAST(1 AS SMALLINT) END AS is_closed
            FROM HBLive.rems.activeper WHERE menucode = 'gl'
            UNION ALL
            SELECT
                CONCAT(compcode, '_', fiscalyear, '_', '9') AS period_id,
                compcode AS company_code,
                fiscalyear AS fiscal_year,
                9 AS period,
                DATEFROMPARTS(CAST(fiscalyear AS INT), 9, 1) AS period_start,
                EOMONTH(DATEFROMPARTS(CAST(fiscalyear AS INT), 9, 1)) AS period_end,
                CASE WHEN isactive##9 = 1 THEN CAST(0 AS SMALLINT) ELSE CAST(1 AS SMALLINT) END AS is_closed
            FROM HBLive.rems.activeper WHERE menucode = 'gl'
            UNION ALL
            SELECT
                CONCAT(compcode, '_', fiscalyear, '_', '10') AS period_id,
                compcode AS company_code,
                fiscalyear AS fiscal_year,
                10 AS period,
                DATEFROMPARTS(CAST(fiscalyear AS INT), 10, 1) AS period_start,
                EOMONTH(DATEFROMPARTS(CAST(fiscalyear AS INT), 10, 1)) AS period_end,
                CASE WHEN isactive##10 = 1 THEN CAST(0 AS SMALLINT) ELSE CAST(1 AS SMALLINT) END AS is_closed
            FROM HBLive.rems.activeper WHERE menucode = 'gl'
            UNION ALL
            SELECT
                CONCAT(compcode, '_', fiscalyear, '_', '11') AS period_id,
                compcode AS company_code,
                fiscalyear AS fiscal_year,
                11 AS period,
                DATEFROMPARTS(CAST(fiscalyear AS INT), 11, 1) AS period_start,
                EOMONTH(DATEFROMPARTS(CAST(fiscalyear AS INT), 11, 1)) AS period_end,
                CASE WHEN isactive##11 = 1 THEN CAST(0 AS SMALLINT) ELSE CAST(1 AS SMALLINT) END AS is_closed
            FROM HBLive.rems.activeper WHERE menucode = 'gl'
            UNION ALL
            SELECT
                CONCAT(compcode, '_', fiscalyear, '_', '12') AS period_id,
                compcode AS company_code,
                fiscalyear AS fiscal_year,
                12 AS period,
                DATEFROMPARTS(CAST(fiscalyear AS INT), 12, 1) AS period_start,
                EOMONTH(DATEFROMPARTS(CAST(fiscalyear AS INT), 12, 1)) AS period_end,
                CASE WHEN isactive##12 = 1 THEN CAST(0 AS SMALLINT) ELSE CAST(1 AS SMALLINT) END AS is_closed
            FROM HBLive.rems.activeper WHERE menucode = 'gl'
        ) AS derived;

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
        IF OBJECT_ID('tempdb..#PREP_02_dim_period') IS NOT NULL DROP TABLE #PREP_02_dim_period;
        SELECT 
            src.*,
            CONVERT(
                VARCHAR(64), 
                HASHBYTES('SHA2_256',
                    CONCAT(
                        ISNULL(TRIM(src.company_code), ''),'~',
                        ISNULL(CONVERT(VARCHAR,src.fiscal_year), ''),'~',
                        ISNULL(CONVERT(VARCHAR,src.period), ''),'~',
                        ISNULL(CONVERT(VARCHAR,src.period_start), ''),'~',
                        ISNULL(CONVERT(VARCHAR,src.period_end), ''),'~',
                        ISNULL(CONVERT(VARCHAR,src.is_closed), '')
                    ) 
                ), 
                2
            ) as record_hash_key,
            @current_datetime AS effective_start_date,
            @current_datetime AS created_date,
            @CreatedBy AS created_by,
            @JobRunId AS created_job_run_id
        INTO #PREP_02_dim_period
        FROM #PREP_01_dim_period as src
        LEFT JOIN dbo.dim_period tgt
            ON src.period_id = tgt.period_id AND tgt.is_active = 'Y';

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
        FROM EDW_Silver.dbo.dim_period tgt
        LEFT JOIN #PREP_02_dim_period src
        ON tgt.period_id = src.period_id
        WHERE src.period_id IS NULL AND tgt.is_active = 'Y';

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
        FROM dbo.dim_period tgt
        JOIN #PREP_02_dim_period src
          ON tgt.period_id = src.period_id
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
        --- STEP 5. Insert new/changed rows ---
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

        INSERT INTO dbo.dim_period (
            period_guid, period_id, company_code, fiscal_year, period, period_start, period_end, is_closed, effective_start_date, 
            effective_end_date, is_active, is_deleted, created_date, created_by, created_job_run_id, record_hash_key
        )
        SELECT
            CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))) AS period_guid,
            src.period_id, 
            src.company_code, 
            src.fiscal_year, 
            src.period, 
            src.period_start, 
            src.period_end, 
            src.is_closed,
            src.effective_start_date,
            @end_date,
            'Y',
            'N',
            src.created_date,
            src.created_by,
            src.created_job_run_id,
            src.record_hash_key
        FROM #PREP_02_dim_period src
        LEFT JOIN dbo.dim_period tgt
            ON src.period_id = tgt.period_id 
                AND tgt.is_active = 'Y'
        WHERE 
        tgt.period_id IS NULL 
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

        SELECT @total_record_count = count(period_guid) FROM EDW_Silver.dbo.dim_period WHERE is_active = 'Y';

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