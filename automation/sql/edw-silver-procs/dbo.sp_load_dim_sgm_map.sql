/*
*******************************************************************************************************************************************************************************************************
    OBJECT NAME    : SP_LOAD_DIM_SGM_MAP
    CREATED BY     : Kamalesh Radhakrishnan
    CREATED ON     : 11/06/2025
    PURPOSE        : Stored procedure for loading dimension tables
    INPUT PARAMS   : JobRunId,MaxDateTime,LoadType,AuditId
    OUT PARAMS     : BOOLEAN
    EXEC Statement : EXEC dbo.sp_load_dim_sgm_map(<JobRunId>, <MaxDate>, <LoadType>, <AuditId>);
*******************************************************************************************************************************************************************************************************
*/

CREATE       PROCEDURE dbo.sp_load_dim_sgm_map
    @CreatedBy      VARCHAR(100) = 'GB_user',
    @JobRunId       VARCHAR(100),
    @LoadType       VARCHAR(20) = '',
    @AuditId        VARCHAR(100) = '',
    @OrchestratorAuditId VARCHAR(100)  = ''

AS
BEGIN

    -- Declare & Define Last Modified Datetime , Audit Id & Load Type --
    --****************************************************************--
    DECLARE @MaxDateTime VARCHAR(100); 
    DECLARE @pipeline_audit_id VARCHAR(100) = @AuditId;
    --DECLARE @AuditId     VARCHAR(100);
    --DECLARE @LoadType     VARCHAR(20);

    IF @AuditId = ''
    BEGIN
        SELECT @AuditId = CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))) ;
    END;

    IF @LoadType = ''
    BEGIN
        SELECT @MaxDateTime = ISNULL(CONVERT(VARCHAR(15), MAX(lastmoddatetime)),'Table is empty') FROM dbo.dim_sgm_map;
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
            @procedure_name = 'sp_load_dim_sgm_map',
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
        IF OBJECT_ID('tempdb..#PREP_00_dim_sgm_map') IS NOT NULL DROP TABLE #PREP_00_dim_sgm_map;
        
        -- Selecting the records which match the lastmoddatetime condition.
        WITH dim_sgm_map_pre AS (
            SELECT
                CONCAT(sgmm.gbp_sgmtypename, '_', maj.major_code, '_', maj.minor_code) AS sgm_map_id,
                sgmt.gbp_category AS category,
                sgmt.gbp_subcategory AS sub_category,
                sgmm.gbp_sgmtypename AS sgm_type,
                sgmt.gbp_description AS description,
                maj.major_code AS major_code,
                maj.major_description AS major_description,
                maj.minor_code AS minor_code,
                maj.minor_description AS minor_description,
                CAST(sgmm.statuscode as SMALLINT) AS sgm_active,
                (
                    SELECT MAX(v.dt)
                    FROM (VALUES
                        (TRY_CAST(FORMAT(sgmm.modifiedon,'yyyyMMdd.HHmmss') AS DECIMAL(17,6))),
                        (ISNULL(TRY_CAST(FORMAT(sgmt.modifiedon,'yyyyMMdd.HHmmss') AS DECIMAL(17,6)), 19500101.000000)),
                        (ISNULL(maj.lastmoddatetime, 19500101.000000))
                    ) AS v(dt)
                ) AS lastmoddatetime
            FROM dataverse_gbpdev.dbo.gbp_sgmmap sgmm
            INNER JOIN dataverse_gbpdev.dbo.gbp_sgmtype sgmt 
                ON sgmm.gbp_sgmtypename = sgmt.gbp_type
            INNER JOIN EDW_Silver.dbo.dim_major_minor maj 
                ON sgmm.gbp_majorcode = maj.major_code
                AND sgmm.gbp_minorcode = maj.minor_code
            WHERE maj.job_type = 'LS'
        ),
        dim_sgm_map AS (
            SELECT
                CONCAT(sgmm.gbp_sgmtypename, '_', maj.major_code, '_', maj.minor_code) AS sgm_map_id,
                sgmt.gbp_category AS category,
                sgmt.gbp_subcategory AS sub_category,
                sgmm.gbp_sgmtypename AS sgm_type,
                sgmt.gbp_description AS description,
                maj.major_code AS major_code,
                maj.major_description AS major_description,
                maj.minor_code AS minor_code,
                maj.minor_description AS minor_description,
                CAST(sgmm.statuscode as SMALLINT) AS sgm_active,
                (
                    SELECT MAX(v.dt)
                    FROM (VALUES
                        (CAST(FORMAT(sgmm.modifiedon,'yyyyMMdd.HHmmss') AS DECIMAL(17,6))),
                        (ISNULL(CAST(FORMAT(sgmt.modifiedon,'yyyyMMdd.HHmmss') AS DECIMAL(17,6)), 19500101.000000)),
                        (ISNULL(maj.lastmoddatetime, 19500101.000000))
                    ) AS v(dt)
                ) AS lastmoddatetime
            FROM dataverse_gbpdev.dbo.gbp_sgmmap sgmm
            INNER JOIN dataverse_gbpdev.dbo.gbp_sgmtype sgmt 
                ON sgmm.gbp_sgmtypename = sgmt.gbp_type
            INNER JOIN EDW_Silver.dbo.dim_major_minor maj 
                ON sgmm.gbp_majorcode = '*'
                AND sgmm.gbp_minorcode = maj.minor_code
            LEFT JOIN dim_sgm_map_pre sgmp
            ON sgmp.major_code = maj.major_code
            AND sgmp.minor_code = maj.minor_code
            WHERE maj.job_type = 'LS'
            AND sgmp.major_code IS NULL
        
            --AND CONCAT(sgmm.gbp_sgmtypename, '_', maj.major_code, '_', maj.minor_code) NOT IN (
            --    SELECT
            --        CONCAT(sgmm_inner.gbp_sgmtypename, '_', maj_inner.major_code, '_', maj_inner.minor_code)
            --    FROM dataverse_gbpdev.dbo.gbp_sgmmap sgmm_inner
            --    INNER JOIN dataverse_gbpdev.dbo.gbp_sgmtype sgmt_inner 
            --        ON sgmm_inner.gbp_sgmtypename = sgmt_inner.gbp_type
            --    INNER JOIN EDW_Silver.dbo.dim_major_minor maj_inner 
            --        ON sgmm_inner.gbp_majorcode = maj_inner.major_code
            --        AND sgmm_inner.gbp_minorcode = maj_inner.minor_code
            --    WHERE maj_inner.job_type = 'LS'
            --)
        ),
        dim_sgm_map_global AS (
            SELECT
                CONCAT(sgmm.gbp_sgmtypename, '_', sgmm.gbp_majorcode, '_', sgmm.gbp_minorcode) AS sgm_map_id,
                sgmt.gbp_category AS category,
                sgmt.gbp_subcategory AS sub_category,
                sgmm.gbp_sgmtypename AS sgm_type,
                sgmt.gbp_description AS description,
                sgmm.gbp_majorcode AS major_code,
                'Global' AS major_description,
                sgmm.gbp_minorcode AS minor_code,
                maj.minor_description AS minor_description,
                CAST(sgmm.statuscode as SMALLINT) AS sgm_active,
                (
                    SELECT MAX(v.dt)
                    FROM (VALUES
                        (TRY_CAST(FORMAT(sgmm.modifiedon,'yyyyMMdd.HHmmss') AS DECIMAL(17,6))),
                        (ISNULL(TRY_CAST(FORMAT(sgmt.modifiedon,'yyyyMMdd.HHmmss') AS DECIMAL(17,6)), 19500101.000000)),
                        (ISNULL(maj.lastmoddatetime, 19500101.000000))
                    ) AS v(dt)
                ) AS lastmoddatetime
            FROM dataverse_gbpdev.dbo.gbp_sgmmap sgmm
            INNER JOIN dataverse_gbpdev.dbo.gbp_sgmtype sgmt 
                ON sgmm.gbp_sgmtypename = sgmt.gbp_type
            INNER JOIN (
                SELECT maj.minor_code, maj.minor_description, MAX(maj.lastmoddatetime) AS lastmoddatetime
                FROM EDW_Silver.dbo.dim_major_minor maj 
                WHERE maj.job_type = 'LS'
                GROUP BY maj.minor_code, maj.minor_description
            ) AS maj
            on maj.minor_code = sgmm.gbp_minorcode
        WHERE sgmm.gbp_majorcode = '*'
        )
        
        SELECT * 
        INTO #PREP_00_dim_sgm_map
        FROM (SELECT * FROM dim_sgm_map_pre UNION ALL SELECT * FROM dim_sgm_map UNION ALL SELECT * FROM dim_sgm_map_global) dsm;

        -- Selecting the records which match the lastmoddatetime condition.
        IF OBJECT_ID('tempdb..#PREP_01_dim_sgm_map') IS NOT NULL DROP TABLE #PREP_01_dim_sgm_map;
        SELECT 
            *
        INTO #PREP_01_dim_sgm_map
        FROM #PREP_00_dim_sgm_map
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

        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Loading PREP_01';
        IF OBJECT_ID('tempdb..#PREP_02_dim_sgm_map') IS NOT NULL DROP TABLE #PREP_02_dim_sgm_map;
        SELECT 
            src.*,
            CONVERT(
                VARCHAR(64), 
                HASHBYTES('SHA2_256',
                    CONCAT(
                        ISNULL(TRIM(src.category), ''),'~',
                        ISNULL(TRIM(src.sub_category), ''),'~',
                        ISNULL(TRIM(src.sgm_type), ''),'~',
                        ISNULL(TRIM(src.description), ''),'~',
                        ISNULL(TRIM(src.major_code), ''),'~',
                        ISNULL(TRIM(src.major_description), ''),'~',
                        ISNULL(TRIM(src.minor_code), ''),'~',
                        ISNULL(TRIM(src.minor_description), ''),'~',
                        ISNULL(CONVERT(VARCHAR,src.sgm_active), '')
                    ) 
                ), 
                2
            ) as record_hash_key,
            @current_datetime AS effective_start_date,
            @current_datetime AS created_date,
            @CreatedBy AS created_by,
            @JobRunId AS created_job_run_id
        INTO #PREP_02_dim_sgm_map 
        FROM #PREP_01_dim_sgm_map as src
        LEFT JOIN dbo.dim_sgm_map tgt
            ON src.sgm_map_id = tgt.sgm_map_id AND tgt.is_active = 'Y';

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
        FROM EDW_Silver.dbo.dim_sgm_map tgt
        LEFT JOIN #PREP_00_dim_sgm_map src
        ON tgt.sgm_map_id = src.sgm_map_id
        WHERE src.sgm_map_id IS NULL AND tgt.is_active = 'Y';

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
        FROM dbo.dim_sgm_map tgt
        JOIN #PREP_02_dim_sgm_map src
          ON tgt.sgm_map_id = src.sgm_map_id
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

        INSERT INTO dbo.dim_sgm_map (
            sgm_map_guid, sgm_map_id, category, sub_category, sgm_type, description, major_code, major_description,
            minor_code, minor_description, sgm_active, lastmoddatetime, effective_start_date, 
            effective_end_date, is_active, is_deleted, created_date, record_hash_key, created_by, created_job_run_id
        )
        SELECT
            CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))) AS sgm_map_guid,
            src.sgm_map_id,
            src.category,
            src.sub_category,
            src.sgm_type,
            src.description,
            src.major_code,
            src.major_description,
            src.minor_code,
            src.minor_description,
            src.sgm_active,
            src.lastmoddatetime,
            src.effective_start_date,
            @end_date,
            'Y',
            'N',
            src.created_date,
            src.record_hash_key,
            src.created_by,
            src.created_job_run_id
        FROM #PREP_02_dim_sgm_map src
        LEFT JOIN dbo.dim_sgm_map tgt
            ON src.sgm_map_id = tgt.sgm_map_id 
                AND tgt.is_active = 'Y'
        WHERE 
        tgt.sgm_map_id IS NULL 
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

        SELECT @total_record_count = count(sgm_map_guid) FROM EDW_Silver.dbo.dim_sgm_map WHERE is_active = 'Y';

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