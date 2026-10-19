/*
*******************************************************************************************************************************************************************************************************
    OBJECT NAME    : SP_LOAD_DIM_PROJECT
    CREATED BY     : Akshaya Dhanraj
    CREATED ON     : 27/05/2025
    PURPOSE        : Stored procedure for loading dimension tables
    INPUT PARAMS   : JobRunId,MaxDate,LoadType
    OUT PARAMS     : BOOLEAN
    EXEC Statement : EXEC dbo.sp_load_dim_project(<JobRunId>, <MaxDate>, <LoadType>);
*******************************************************************************************************************************************************************************************************
*/
CREATE           PROCEDURE dbo.sp_load_dim_project

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
            SELECT @MaxDateTime = ISNULL(CONVERT(VARCHAR(15), MAX(lastmoddatetime)),'Table is empty') FROM dbo.dim_project;
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
            @procedure_name   = 'sp_load_dim_project',
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
        IF OBJECT_ID('tempdb..#PREP_01_dim_project') IS NOT NULL DROP TABLE #PREP_01_dim_project;

        WITH CTE_jobphase AS (
            SELECT jp1.projid, COUNT(jp1.phase) AS system_lots
            FROM HBLive.rems.jobphase jp1
            WHERE jp1.userdef##1 = 0
            GROUP BY jp1.projid
        ),
        dim_project AS (
            SELECT
                p1.ounitcode AS operating_unit_code,
                CASE WHEN p1.userdef##10 = '' THEN p1.ounitcode ELSE p1.userdef##10 END AS reporting_operating_unit_code,
                p1.projcode AS project_code,
                p1.projid AS project_id,
                p1.name AS project_name,
                CONCAT(p1.projcode,'-',p1.name) AS project_label,
                p1.projtype AS project_type,
                p1.compcode AS company_code,
                p1.divcode AS division_code,
                a1.street, 
                a1.street2, 
                a1.suite, 
                a1.postal AS zip,
                c1.cityname AS city, 
                c1.provcode AS state,
                s1.County AS county,
                p1.userdef##6 AS area_constr_mgr,
                p1.userdefnumeric##10 AS total_lots,
                jp1.system_lots,
                p1.userdeflog##2 AS exclude,
                p1.wrmonths AS warranty_months,
                p1.consttype AS constr_type,
                s1.LegalCompName AS legal_comp_name,
                p1.iflag##3 AS buildpro_integrated,
                p1.mflag##3 AS buildpro_modified,
                COALESCE(CAST(o1.org_id AS VARCHAR(20)),'') AS buildpro_org_num,
                p1.epoemail AS epo_email,
                p1.hidden, p1.archived,
                p1.userdeflog##4 AS land_project,
                s1.SubdivisionID AS subdivision_id,
                (
                    SELECT MAX(v.dt)
                    FROM (VALUES
                        (p1.lastmoddatetime),
                        (ISNULL(a1.lastmoddatetime, '19500101.000000')),
                        (ISNULL(c1.lastmoddatetime, '19500101.000000'))
                    ) AS v(dt)
                ) AS lastmoddatetime
            FROM HBLive.rems.project p1
            LEFT JOIN HBLive.rems.address a1 ON p1.aid = a1.aid
            LEFT JOIN HBLive.rems.city c1 ON a1.citycode = c1.citycode
            LEFT JOIN SPLive.dbo.Subdivisions s1 ON p1.projid = s1.i_ProjID
            LEFT JOIN BuildPro.dbo.mh4_org o1 ON o1.org_num = p1.projid
            LEFT JOIN CTE_jobphase jp1 ON p1.projid = jp1.projid
        )
        SELECT * 
        INTO #PREP_01_dim_project
        FROM dim_project dp1
        WHERE 
            CASE 
                WHEN @LoadType = 'FULL' THEN 1
                WHEN @LoadType = 'INCREMENTAL' AND CONVERT(VARCHAR(15), dp1.lastmoddatetime) > @MaxDateTime THEN 1
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
        IF OBJECT_ID('tempdb..#PREP_02_dim_project') IS NOT NULL DROP TABLE #PREP_02_dim_project;

        SELECT
            src.*,
            CONVERT(VARCHAR(64), HASHBYTES('SHA2_256',
            CONCAT(
                ISNULL(TRIM(src.operating_unit_code), ''), '~',
                ISNULL(TRIM(src.reporting_operating_unit_code), ''), '~',
                ISNULL(TRIM(src.project_code), ''), '~',
                ISNULL(TRIM(src.project_name), ''), '~',
                ISNULL(TRIM(src.project_label), ''), '~',
                ISNULL(TRIM(src.project_type), ''), '~',
                ISNULL(TRIM(src.company_code), ''), '~',
                ISNULL(TRIM(src.division_code), ''), '~',
                ISNULL(TRIM(src.street), ''), '~',
                ISNULL(TRIM(src.street2), ''), '~',
                ISNULL(TRIM(src.suite), ''), '~',
                ISNULL(TRIM(src.zip), ''), '~',
                ISNULL(TRIM(src.city), ''), '~',
                ISNULL(TRIM(src.state), ''), '~',
                ISNULL(TRIM(src.county), ''), '~',
                ISNULL(TRIM(src.area_constr_mgr), ''), '~',
                ISNULL(CAST(src.total_lots AS VARCHAR), ''), '~',
                ISNULL(CAST(src.system_lots AS VARCHAR), ''), '~',
                ISNULL(CAST(src.exclude AS VARCHAR), ''), '~',
                ISNULL(CAST(src.warranty_months AS VARCHAR), ''), '~',
                ISNULL(TRIM(src.constr_type), ''), '~',
                ISNULL(TRIM(src.legal_comp_name), ''), '~',
                ISNULL(CAST(src.buildpro_integrated AS VARCHAR), ''), '~',
                ISNULL(CAST(src.buildpro_modified AS VARCHAR), ''), '~',
                ISNULL(TRIM(src.buildpro_org_num), ''), '~',
                ISNULL(TRIM(src.epo_email), ''), '~',
                ISNULL(CAST(src.hidden AS VARCHAR), ''), '~',
                ISNULL(CAST(src.archived AS VARCHAR), ''), '~',
                ISNULL(CAST(src.land_project AS VARCHAR), ''), '~',
                ISNULL(CAST(src.subdivision_id AS VARCHAR), '')
            )), 2) AS record_hash_key,
            @current_datetime AS effective_start_date,
            @current_datetime AS created_date,
            @CreatedBy AS created_by,
            @JobRunId AS created_job_run_id
        INTO #PREP_02_dim_project    
        FROM #PREP_01_dim_project src
        LEFT JOIN dbo.dim_project tgt
          ON src.project_id = tgt.project_id AND tgt.is_active = 'Y';

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
        FROM EDW_Silver.dbo.dim_project tgt
        LEFT JOIN HBLive.rems.project src ON tgt.project_id = src.projid
        WHERE src.projid IS NULL AND tgt.is_active = 'Y';

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
        FROM dbo.dim_project tgt
        JOIN #PREP_02_dim_project src
          ON tgt.project_id = src.project_id
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

        INSERT INTO dbo.dim_project (
            project_guid, operating_unit_code, reporting_operating_unit_code, project_code, project_id,
            project_name, project_label, project_type, company_code, division_code,
            street, street2, suite, zip, city, state, county,
            area_constr_mgr, total_lots, system_lots, exclude, warranty_months,
            constr_type, legal_comp_name, buildpro_integrated, buildpro_modified,
            buildpro_org_num, epo_email, hidden, archived, land_project,
            subdivision_id, lastmoddatetime,
            effective_start_date, effective_end_date, is_active, is_deleted,
            created_date, created_by, created_job_run_id, record_hash_key
        )
        SELECT
            CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))), src.operating_unit_code, src.reporting_operating_unit_code, src.project_code, src.project_id,
            src.project_name, src.project_label, src.project_type, src.company_code, src.division_code,
            src.street, src.street2, src.suite, src.zip, src.city, src.state, src.county,
            src.area_constr_mgr, src.total_lots, src.system_lots, src.exclude, src.warranty_months,
            src.constr_type, src.legal_comp_name, src.buildpro_integrated, src.buildpro_modified,
            src.buildpro_org_num, src.epo_email, src.hidden, src.archived, src.land_project,
            src.subdivision_id, src.lastmoddatetime,
            src.effective_start_date, @end_date, 'Y','N',
            src.created_date, src.created_by, src.created_job_run_id, src.record_hash_key
        FROM #PREP_02_dim_project src
        LEFT JOIN dbo.dim_project tgt
          ON src.project_id = tgt.project_id AND tgt.is_active = 'Y'
        WHERE tgt.project_id IS NULL OR tgt.record_hash_key <> src.record_hash_key;

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

        SELECT @total_record_count = count(project_guid) FROM EDW_Silver.dbo.dim_project WHERE is_active = 'Y';

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
