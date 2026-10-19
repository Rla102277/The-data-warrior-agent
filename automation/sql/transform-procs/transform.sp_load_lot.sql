/*
*******************************************************************************************************************************************************************************************************
    OBJECT NAME    : SP_LOAD_DIM_LOT
    CREATED BY     : Akshaya Dhanraj
    CREATED ON     : 27/05/2025
    PURPOSE        : Stored procedure for loading dimension tables
    INPUT PARAMS   : JobRunId,MaxDate,LoadType
    OUT PARAMS     : BOOLEAN
    EXEC Statement : EXEC transform.sp_load_lot(<JobRunId>, <MaxDate>, <LoadType>);
*******************************************************************************************************************************************************************************************************
*/
CREATE         PROCEDURE transform.sp_load_lot

    @CreatedBy    VARCHAR(100) = 'GB_user',
    @JobRunId     VARCHAR(100),
    @LoadType     VARCHAR(20),
    @AuditId      VARCHAR(100),
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
        SELECT @MaxDateTime = ISNULL(CONVERT(VARCHAR(15), MAX(lastmoddatetime)),'Table is empty') FROM transform.lot;
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
            @procedure_name   = 'sp_load_lot',
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
        IF OBJECT_ID('tempdb..#PREP_01_dim_lot') IS NOT NULL DROP TABLE #PREP_01_dim_lot;

        WITH CTE_LotExclusions AS (
            SELECT
                DISTINCT 
                jp1.projid,
                jp1.phase,
                ExcludeReason = CASE 
                    WHEN p1.userdeflog##2 = 1 THEN 'Project'
                    WHEN j1.projid IS NOT NULL THEN 'Soft Cost Lot'
                    WHEN jps1.projid IS NOT NULL THEN 'Shell Lot'
                    WHEN jp1.userdeflog##1 = 1 THEN 'Lot'
                END
            FROM HBLive.rems.project p1 
            INNER JOIN HBLive.rems.jobphase jp1 
                ON jp1.projid = p1.projid
            LEFT JOIN HBLive.rems.job j1 
                ON j1.projid = jp1.projid AND j1.softcostlot = jp1.phase
            LEFT JOIN HBLive.rems.jobphase jps1 
                ON jps1.projid = p1.projid AND jps1.shelllot = jp1.phase
            WHERE 
                p1.userdeflog##2 = 1 OR 
                jp1.userdeflog##1 = 1 OR 
                j1.projid IS NOT NULL OR 
                jps1.phase IS NOT NULL
        )
        SELECT *
        INTO #PREP_01_dim_lot
        FROM (
        SELECT 
            jp1.projid AS project_id,
            CONCAT(jp1.projid , '_' , jp1.phase) AS lot_id,
            CONCAT(jp1.phase , CASE WHEN jpa1.streetno IS NOT NULL THEN '_' + jpa1.streetno ELSE '' END,CASE WHEN jpa1.street IS NOT NULL THEN ' ' + jpa1.street ELSE '' END, CASE WHEN jpa1.street2 IS NOT NULL THEN ' ' + jpa1.street2 ELSE '' END) AS lot_label,
            jp1.phase AS lot_number,
            CONCAT(CASE WHEN jpa1.streetno IS NOT NULL THEN jpa1.streetno ELSE '' END, CASE WHEN jpa1.street IS NOT NULL THEN ' ' + jpa1.street ELSE '' END) AS street,
            jpa1.street2,
            jpa1.suite,
            c1.cityname AS city,
            c1.provcode AS state,
            jpa1.postal AS zip,
            CASE 
                WHEN js1.actualdateclosed IS NOT NULL THEN 'Closed'
                WHEN ds1.approved_date IS NOT NULL AND ds1.cancel_date IS NULL THEN 'Backlog'
                WHEN dj1.start_date IS NOT NULL
                    AND (UPPER(jp1.lottype) <> 'MODEL' OR jp1.releasedate IS NOT NULL) 
                THEN 'Spec'
                WHEN dj1.start_date IS NOT NULL	
                    AND (UPPER(jp1.lottype) = 'MODEL'
                    AND jp1.releasedate IS NULL)
                THEN 'Model'
                ELSE 'Open'
            END AS lot_status,
            jp1.lottype AS lot_type,
            jp1.permitreceiveddate AS permit_date,
            jp1.releasedate AS release_date,
            jp1.userdefdate##3 AS takedown_date,
            jp1.userdefdate##4 AS lot_transfer_date,
            jp1.userdef##3 AS loan_status,
            jp1.userdef##4 AS notes_1,
            jp1.userdef##5 AS notes_2,
            jp1.model AS plan_code,
            jm1.descr AS plan_description,
            jp1.elev AS elevation,
            jm1.area AS base_square_footage,
            CASE 
                WHEN js1.revisedclosing IS NULL OR js1.revisedclosing = '' 
                THEN jp1.userdefdate##5 
                ELSE js1.revisedclosing 
            END AS revised_close_date,
            js1.actualdateclosed AS close_date,
            CASE WHEN ds1.sales_status = 'Backlog' THEN 1 ELSE 0 END AS is_backlog,
            CASE WHEN js1.actualdateclosed IS NOT NULL THEN 1 ELSE 0 END AS is_closed, 
            CASE 
                WHEN js1.actualdateclosed IS NULL
                    AND ds1.approved_date IS NULL
                    AND dj1.start_date IS NOT NULL
                    AND (UPPER(jp1.lottype) <> 'MODEL' OR jp1.releasedate IS NOT NULL) 
                THEN 1 ELSE 0 END AS is_spec,
            CASE 
                WHEN js1.actualdateclosed IS NULL
                    AND ds1.approved_date IS NULL
                    AND dj1.start_date IS NOT NULL
                    AND (UPPER(jp1.lottype) = 'MODEL' OR jp1.releasedate IS NULL) 
                THEN 1 ELSE 0 END AS is_model,
            CASE WHEN jp1.userdefdate##3 IS NOT NULL THEN 1 ELSE 0 END AS is_owned,
            CASE WHEN dj1.start_date IS NOT NULL THEN 1 ELSE 0 END AS is_started,
            CASE WHEN dj1.complete_date IS NOT NULL THEN 1 ELSE 0 END AS is_completed,
            CASE 
                WHEN ds1.sales_status = 'Backlog' 
                    AND dj1.start_date IS NOT NULL 
                THEN 1 ELSE 0 
            END AS sold_not_started,
            COALESCE(COALESCE(js1.actualdateclosed, 
                CASE 
                    WHEN js1.revisedclosing IS NULL OR js1.revisedclosing = '' 
                    THEN jp1.userdefdate##5 
                    ELSE js1.revisedclosing 
                END), dj1.complete_date) AS close_reporting_date,
            sdl1.SDLotID AS sd_lot_id,
            CASE WHEN jp1.softcostlot = 1 THEN 1 ELSE 0 END AS is_soft_cost_lot,
            jp1.shelllot AS shell_lot,
            CASE WHEN pd1.phase IS NOT NULL THEN 1 ELSE 0 END AS exclude_from_reporting,
            pd1.ExcludeReason AS exclude_reason,
            (SELECT MAX(v.dt)
                FROM (VALUES
                    (jp1.lastmoddatetime),
                    (ISNULL(jpa1.lastmoddatetime, 19500101.000000)),
                    (ISNULL(c1.lastmoddatetime, 19500101.000000)),
                    (ISNULL(jm1.lastmoddatetime, 19500101.000000)),
                    (ISNULL(js1.lastmoddatetime, 19500101.000000)),
                    (CAST(CONVERT(CHAR(8), sdl1.LastModified, 112) AS VARCHAR) + '.' +
                        REPLACE(CONVERT(CHAR(8), sdl1.LastModified, 108), ':', '')),
                    (ISNULL(ds1.lastmoddatetime, 19500101.000000)),
                    (ISNULL(dj1.lastmoddatetime, 19500101.000000))
                ) AS v(dt)
    ) AS lastmoddatetime
        FROM HBLive.rems.jobphase jp1 
        LEFT JOIN HBLive.rems.jobphaseaddr jpa1 ON jp1.projid = jpa1.projid AND jp1.phase = jpa1.phase
        LEFT JOIN HBLive.rems.city c1 ON jpa1.citycode = c1.citycode
        LEFT JOIN HBLive.rems.jobmodel jm1 ON jp1.projid = jm1.projid AND jp1.model = jm1.model AND jp1.elev = jm1.elev
        LEFT JOIN HBLive.rems.jobsales js1 ON jp1.projid = js1.projid AND jp1.phase = js1.phase
        LEFT JOIN SPLive.dbo.SDLots sdl1 ON jp1.projid = sdl1.i_ProjID AND jp1.phase = sdl1.i_Phase
        LEFT JOIN CTE_LotExclusions pd1 ON jp1.projid = pd1.projid AND jp1.phase = pd1.phase
        LEFT JOIN transform.sale ds1 ON CONCAT(jp1.projid , '_' , jp1.phase) = ds1.lot_id AND ds1.sales_status IN ('Backlog','Closed') AND js1.i_recid = CAST(ds1.sale_id AS VARCHAR(50)) AND ds1.is_active = 'Y' --CHANGE
        LEFT JOIN transform.job dj1 ON CONCAT(jp1.projid , '_' , jp1.phase) = dj1.lot_id AND dj1.job_active = 1 AND dj1.is_active = 'Y'
        ) dim_lot
        WHERE 
            CASE WHEN @LoadType = 'FULL' THEN 1
                 WHEN @LoadType = 'INCREMENTAL' 
                 AND CONVERT(VARCHAR(15), lastmoddatetime) > @MaxDateTime THEN 1
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
        IF OBJECT_ID('tempdb..#PREP_02_dim_lot') IS NOT NULL DROP TABLE #PREP_02_dim_lot;

        SELECT
            src.*,
            CONVERT(VARCHAR(64), HASHBYTES('SHA2_256',
            CONCAT(
            ISNULL(TRIM(src.project_id), ''), '~',
            ISNULL(TRIM(src.lot_label), ''), '~',
            ISNULL(TRIM(src.lot_number), ''), '~',
            ISNULL(TRIM(src.street), ''), '~',
            ISNULL(TRIM(src.street2), ''), '~',
            ISNULL(TRIM(src.suite), ''), '~',
            ISNULL(TRIM(src.city), ''), '~',
            ISNULL(TRIM(src.state), ''), '~',
            ISNULL(TRIM(src.zip), ''), '~',
            ISNULL(TRIM(src.lot_status), ''), '~',
            ISNULL(TRIM(src.lot_type), ''), '~',
            ISNULL(CAST(src.permit_date AS VARCHAR), ''), '~',
            ISNULL(CAST(src.release_date AS VARCHAR), ''), '~',
            ISNULL(CAST(src.takedown_date AS VARCHAR), ''), '~',
            ISNULL(CAST(src.lot_transfer_date AS VARCHAR), ''), '~',
            ISNULL(TRIM(src.loan_status), ''), '~',
            ISNULL(TRIM(src.notes_1), ''), '~',
            ISNULL(TRIM(src.notes_2), ''), '~',
            ISNULL(TRIM(src.plan_code), ''), '~',
            ISNULL(TRIM(src.plan_description), ''), '~',
            ISNULL(TRIM(src.elevation), ''), '~',
            ISNULL(CAST(src.base_square_footage AS VARCHAR), ''), '~',
            ISNULL(CAST(src.revised_close_date AS VARCHAR), ''), '~',
            ISNULL(CAST(src.close_date AS VARCHAR), ''), '~',
            ISNULL(CAST(src.is_backlog AS VARCHAR), ''), '~',
            ISNULL(CAST(src.is_closed AS VARCHAR), ''), '~',
            ISNULL(CAST(src.is_spec AS VARCHAR), ''), '~',
            ISNULL(CAST(src.is_model AS VARCHAR), ''), '~',
            ISNULL(CAST(src.is_owned AS VARCHAR), ''), '~',
            ISNULL(CAST(src.is_started AS VARCHAR), ''), '~',
            ISNULL(CAST(src.is_completed AS VARCHAR), ''), '~',
            ISNULL(CAST(src.sold_not_started AS VARCHAR), ''), '~',
            ISNULL(CAST(src.close_reporting_date AS VARCHAR), ''), '~',
            ISNULL(CAST(src.sd_lot_id AS VARCHAR), ''), '~',
            ISNULL(CAST(src.is_soft_cost_lot AS VARCHAR), ''), '~',
            ISNULL(TRIM(src.shell_lot), ''), '~',
            ISNULL(CAST(src.exclude_from_reporting AS VARCHAR), ''), '~',
            ISNULL(TRIM(src.exclude_reason), '')
            )
            ), 2) AS record_hash_key,
            @current_datetime AS effective_start_date,
            @current_datetime AS created_date,
            @CreatedBy AS created_by,
            @JobRunId AS created_job_run_id
        INTO #PREP_02_dim_lot    
        FROM #PREP_01_dim_lot src

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
        FROM transform.lot tgt
        LEFT JOIN HBLive.rems.jobphase src
        ON tgt.lot_id = CONCAT(src.projid , '_' , src.phase)
        WHERE CONCAT(src.projid , '_' , src.phase) IS NULL AND tgt.is_active = 'Y';

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
        FROM transform.lot tgt
        JOIN #PREP_02_dim_lot src
          ON tgt.lot_id = src.lot_id
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

        INSERT INTO transform.lot (
            lot_guid, project_id,lot_id,lot_label,lot_number,street,street2
            ,suite,city,state,zip,lot_status,lot_type
            ,permit_date,release_date,takedown_date,lot_transfer_date
            ,loan_status,notes_1,notes_2,plan_code,plan_description
            ,elevation,base_square_footage,revised_close_date,close_date
            ,is_backlog,is_closed,is_spec,is_model,is_owned,is_started
            ,is_completed,sold_not_started,close_reporting_date,sd_lot_id
            ,is_soft_cost_lot,shell_lot,exclude_from_reporting,exclude_reason,lastmoddatetime,
            effective_start_date, effective_end_date, is_active, is_deleted,
            created_date, created_by, created_job_run_id, record_hash_key
        )
        SELECT
            CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))), src.project_id,src.lot_id,src.lot_label,src.lot_number,src.street,src.street2
            ,src.suite,src.city,src.state,src.zip,src.lot_status,src.lot_type
            ,src.permit_date,src.release_date,src.takedown_date,src.lot_transfer_date
            ,src.loan_status,src.notes_1,src.notes_2,src.plan_code,src.plan_description
            ,src.elevation,src.base_square_footage,src.revised_close_date,src.close_date
            ,src.is_backlog,src.is_closed,src.is_spec,src.is_model,src.is_owned,src.is_started
            ,src.is_completed,src.sold_not_started,src.close_reporting_date,src.sd_lot_id
            ,src.is_soft_cost_lot,src.shell_lot,src.exclude_from_reporting,src.exclude_reason,src.lastmoddatetime,
            src.effective_start_date, @end_date, 'Y', 'N',
            src.created_date, src.created_by, src.created_job_run_id, src.record_hash_key
        FROM #PREP_02_dim_lot src
        LEFT JOIN transform.lot tgt
          ON src.lot_id = tgt.lot_id AND tgt.is_active = 'Y'
        WHERE tgt.lot_id IS NULL OR tgt.record_hash_key <> src.record_hash_key;


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

        SELECT @total_record_count = count(lot_guid) FROM transform.lot WHERE is_active = 'Y';

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
