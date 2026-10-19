/*
*******************************************************************************************************************************************************************************************************
    OBJECT NAME    : SP_LOAD_FACT_LOT_SGM
    CREATED BY     : Kamalesh Radhakrishnan
    CREATED ON     : 01/08/2025
    PURPOSE        : Stored procedure for loading fact tables
    INPUT PARAMS   : JobRunId,MaxDateTime,LoadType,AuditId
    OUT PARAMS     : BOOLEAN
    EXEC Statement : EXEC transform.sp_load_lot_sales_gross_margin_det(<JobRunId>, <MaxDate>, <LoadType>, <AuditId>);
*******************************************************************************************************************************************************************************************************
*/

CREATE     PROCEDURE transform.sp_load_lot_sales_gross_margin_det
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
    DECLARE @MaxDateTime VARCHAR(100);
    DECLARE @pipeline_audit_id VARCHAR(100) = @AuditId;

    IF @AuditId = ''
    BEGIN
        SELECT @AuditId = CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE())));
    END;
    IF @LoadType = 'FULL'
    BEGIN
        TRUNCATE TABLE transform.lot_sales_gross_margin_det;
        PRINT 'Load type is FULL. transform.lot_sales_gross_margin_det table truncated.'
    END
    ELSE IF @LoadType = ''
    BEGIN
        SELECT @MaxDateTime = ISNULL(CONVERT(VARCHAR(15), MAX(lastmoddatetime)),'Table is empty') FROM transform.lot_sales_gross_margin_det;
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
            @procedure_name = 'sp_load_lot_sales_gross_margin_det',
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

        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Loading PREP_00 & PREP_01';
        IF OBJECT_ID('tempdb..#PREP_00_fact_lot_sgm') IS NOT NULL DROP TABLE #PREP_00_fact_lot_sgm;
        IF OBJECT_ID('tempdb..#PREP_01_fact_lot_sgm') IS NOT NULL DROP TABLE #PREP_01_fact_lot_sgm;
        WITH SGMAssumptionsData AS (
            SELECT 
                dl.lot_id AS lot_id,
                fsa.sgm_assumptions_id AS sgm_assumptions_id,
                fsa.assumption_id AS assumption_id,
                fsa.assumption_value_id AS assumption_value_id,
                dsm.category AS sgm_category,
                dsm.sub_category AS sgm_sub_category,
                dsm.sgm_type AS sgm_type,
                fsa.major_code AS major_code,
                fsa.minor_code AS minor_code,
                fsa.trigger1_name AS trigger1_name,
                fsa.trigger1_met AS trigger1_met,
                fsa.trigger2_name AS trigger2_name,
                fsa.trigger2_met AS trigger2_met,
                fsa.calculation_basis AS calculation_basis,
                fsa.gl_amount AS gl_actual,
                fsa.latest_est_amount AS latest_est_amount,
                fsa.calculation_amount AS amount_assumption,
                fsa.use_assumption AS use_assumption,
                CASE 
                    WHEN fsa.use_assumption = 1 
                        THEN fsa.calculation_amount
                    ELSE fsa.latest_est_amount
                END AS amount,
                (
                    SELECT MAX(v.dt)
                    FROM ( VALUES
                        (ISNULL (dl.lastmoddatetime, 19500101.000000)),
                        (ISNULL (fsa.lastmoddatetime, 19500101.000000)),
                        (ISNULL (dsm.lastmoddatetime, 19500101.000000))
                    ) AS v (dt)
                ) AS lastmoddatetime
            FROM transform.sales_gross_margin_assumptions_det fsa
                INNER JOIN transform.lot  dl
                    ON dl.lot_id = fsa.lot_id
                    AND dl.is_active = 'Y'
                INNER JOIN transform.project dp
                    ON dp.project_id = dl.project_id
                    AND dp.is_active = 'Y'
                INNER JOIN transform.sales_gross_margin_map dsm
                    ON dsm.major_code = fsa.major_code
                    AND dsm.minor_code = fsa.minor_code
                    AND dsm.is_active = 'Y'
                LEFT JOIN transform.fiscal_period dp1
                    ON dp1.company_code = dp.company_code
                    AND CAST(EOMONTH(dl.close_date) AS DATE) = dp1.period_end
                    AND dp1.is_closed = 1
                    AND dp1.is_active = 'Y'
            WHERE dp1.company_code IS NULL
        ),
        FactLotSGM AS (
            -- Second dataset from transform.lot_financials_det with exclusion join
            SELECT 
                dl.lot_id AS lot_id,
                '' AS sgm_assumptions_id,
                '' AS assumption_id,
                '' AS assumption_value_id,
                dsm.category AS sgm_category,
                dsm.sub_category AS sgm_sub_category,
                dsm.sgm_type AS sgm_type,
                flf.major_code AS major_code,
                flf.minor_code AS minor_code,
                '' AS trigger1_name,
                '' AS trigger1_met,
                '' AS trigger2_name,
                '' AS trigger2_met,
                '' AS calculation_basis,
                COALESCE(flf.gl_amount,0) AS gl_actual,
                COALESCE(flf.latest_est_amount,0) AS latest_est_amount,
                0 AS amount_assumption,
                0 AS use_assumption,
                COALESCE(CASE 
                    WHEN (dp1.is_closed = 1 OR dp1.is_closed IS NULL)
                        THEN flf.gl_amount
                    ELSE flf.latest_est_amount
                END,0) AS amount,
                (
                    SELECT MAX(v.dt)
                    FROM ( VALUES
                        (ISNULL (dl.lastmoddatetime, 19500101.000000)),
                        (ISNULL (flf.lastmoddatetime, 19500101.000000)),
                        (ISNULL (dsm.lastmoddatetime, 19500101.000000))
                    ) AS v (dt)
                ) AS lastmoddatetime
            FROM transform.lot_financials_det flf
                INNER JOIN transform.lot  dl
                    ON dl.lot_id = flf.lot_id
                    AND dl.is_active = 'Y'
                INNER JOIN transform.project dp
                    ON dp.project_id = dl.project_id
                        AND dp.is_active = 'Y'
                INNER JOIN transform.sales_gross_margin_map dsm
                    ON dsm.sgm_type = flf.sgm_type
                    AND dsm.major_code = flf.major_code
                    AND dsm.minor_code = flf.minor_code
                    AND dsm.is_active = 'Y'
                LEFT JOIN transform.fiscal_period dp1
                    ON dp1.company_code = dp.company_code
                    AND CAST(EOMONTH(dl.close_date) AS DATE) = dp1.period_end
                    AND dp1.is_active = 'Y'
                LEFT JOIN SGMAssumptionsData pl
                    ON pl.lot_id = flf.lot_id
                    AND (pl.major_code = '*' or pl.major_code = flf.major_code)
                    AND pl.minor_code = flf.minor_code
            WHERE pl.lot_id IS NULL

            UNION ALL

            SELECT * FROM SGMAssumptionsData
        )
        SELECT CONCAT(lot_id,'_',major_code,'_',minor_code) AS lot_sgm_id, * INTO #PREP_00_fact_lot_sgm FROM FactLotSGM;

        SELECT * 
        INTO #PREP_01_fact_lot_sgm
        FROM #PREP_00_fact_lot_sgm
        WHERE 
            CASE 
                WHEN @LoadType = 'FULL' THEN 1
                WHEN @LoadType = 'INCREMENTAL' AND CONVERT(VARCHAR(15), lastmoddatetime)> @MaxDateTime THEN 1
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
        IF OBJECT_ID('tempdb..#PREP_02_fact_lot_sgm') IS NOT NULL DROP TABLE #PREP_02_fact_lot_sgm;
        SELECT 
            src.*,
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
        INTO #PREP_02_fact_lot_sgm 
        FROM #PREP_01_fact_lot_sgm as src

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
            @step_name = 'Delete hard-deleted records',
            @step_description = 'Delete hard-deleted records',
            @return_id = @step_audit_id OUTPUT;
        --*************************--

        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Delete hard-deleted records';
        DELETE tgt
        FROM transform.lot_sales_gross_margin_det tgt
        JOIN #PREP_00_fact_lot_sgm src
            ON src.lot_sgm_id = tgt.lot_sgm_id
        WHERE src.lot_sgm_id IS NULL;

        -- End Step3 Run Audit --
        --*************************--
        SET @records_affected = @@ROWCOUNT;
        SET @total_deleted += @records_affected;
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
            @step_name = 'Delete updated records',
            @step_description = 'Delete updated records',
            @return_id = @step_audit_id OUTPUT;
        --*************************--

        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Delete updated records';
        DELETE tgt
        FROM transform.lot_sales_gross_margin_det tgt
        JOIN #PREP_02_fact_lot_sgm src
            ON src.lot_sgm_id = tgt.lot_sgm_id
        WHERE tgt.record_hash_key <> src.record_hash_key;

        -- End Step4 Run Audit --
        --*************************--
        SET @records_affected = @@ROWCOUNT;
        SET @total_deleted += @records_affected;
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
        INSERT INTO transform.lot_sales_gross_margin_det (
            lot_sgm_guid, lot_sgm_id, lot_id, sgm_assumptions_id, assumption_id, assumption_value_id, sgm_category, sgm_sub_category,
            sgm_type, major_code, minor_code, trigger1_name, trigger1_met, trigger2_name, trigger2_met, calculation_basis, gl_actual,
            latest_est_amount, amount_assumption, use_assumption, amount, lastmoddatetime, created_date, record_hash_key, created_by,
            created_job_run_id
        )
        SELECT
            CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))) AS lot_sgm_guid,
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
            src.created_date,
            src.record_hash_key,
            src.created_by,
            src.created_job_run_id
        FROM #PREP_02_fact_lot_sgm src
        LEFT JOIN transform.lot_sales_gross_margin_det tgt
            ON src.lot_sgm_id = tgt.lot_sgm_id
        WHERE 
        tgt.lot_sgm_id IS NULL;

        
 
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

        SELECT @total_record_count = count(lot_sgm_guid) FROM transform.lot_sales_gross_margin_det;

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
    END CATCH
END;
