/*
*******************************************************************************************************************************************************************************************************
    OBJECT NAME    : SP_LOAD_FACT_GENERAL_LEDGER
    CREATED BY     : Akshaya Dhanraj
    CREATED ON     : 27/05/2025
    PURPOSE        : Stored procedure for loading fact tables
    INPUT PARAMS   : JobRunId,MaxDate,LoadType
    OUT PARAMS     : BOOLEAN
    EXEC Statement : EXEC transform.sp_load_general_ledger_det(<JobRunId>, <MaxDate>, <LoadType>);
*******************************************************************************************************************************************************************************************************
*/

CREATE     PROCEDURE transform.sp_load_general_ledger_det
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
        SELECT @AuditId = CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))) ;
    END;

    IF @LoadType = 'FULL'
    BEGIN
        TRUNCATE TABLE transform.general_ledger_det;
        PRINT 'Load type is FULL. transform.general_ledger_det table truncated.'
    END
    ELSE IF @LoadType = ''
    BEGIN
        SELECT @MaxDateTime = ISNULL(CONVERT(VARCHAR(15), MAX(lastmoddatetime)),'Table is empty') FROM transform.general_ledger_det;
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
            @procedure_name = 'sp_load_general_ledger_det',
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
        
        IF OBJECT_ID('tempdb..#PREP_01_fact_general_ledger') IS NOT NULL DROP TABLE #PREP_01_fact_general_ledger;

        SELECT *
        INTO #PREP_01_fact_general_ledger
        FROM (SELECT 
        CONCAT(d1.groupno,'_',d1.unitno,'_',d1.transno) AS gl_detail_id
        ,d1.groupno AS group_number
        ,d1.unitno AS unit_number
        ,d1.transno AS transaction_number -- This has negative values
        ,d1.compcode AS company_code
        ,d1.divcode AS division_code
        ,ca1.targetacctcode AS target_acct_code
        ,a2.acctname AS target_acct_name
        ,d1.acctcode AS source_acct_code
        ,a1.acctname AS source_acct_name
        ,d1.postingdate AS posting_date
        ,CONCAT(TRIM(au1.memo##1) , ' ' , TRIM(au1.memo##2) , ' ' , TRIM(au1.memo##3) , ' ' , TRIM(au1.memo##4) , ' ' , TRIM(au1.memo##5)) AS memo_1
        ,d1.memo AS memo_2
        ,d1.amount
        ,CONCAT(d1.projid , '_' , d1.phase) AS lot_id
        ,d1.majorcode AS major_code
        ,d1.minorcode AS minor_code
        ,ag1.progcode AS program_code
        ,ag1.sourceprogcode AS source_program_code
        ,up1.opername AS gl_created_by
        /*,CAST(ag1.createdate AS DATETIME) +
            CAST(
                TRY_CAST(
                    RIGHT('0' + LEFT(RIGHT('0000' + CAST(ag1.createtime AS VARCHAR), 4), 2), 2) + ':' +
                    RIGHT(RIGHT('0000' + CAST(ag1.createtime AS VARCHAR), 2), 2) + ':00'
                    AS DATETIME
                ) AS DATETIME
            ) AS gl_created_date*/
        ,DATEADD(
        MINUTE,
        CAST(SUBSTRING(REPLACE(ag1.createtime, ':', ''), 3, 2) AS INT) - DATEPART(MINUTE, ag1.createdate),
        DATEADD(
            HOUR,
            CAST(LEFT(REPLACE(ag1.createtime, ':', ''), 2) AS INT) - DATEPART(HOUR, ag1.createdate),
            ag1.createdate
        )
        ) AS gl_created_date
        ,aup1.opername AS approved_by
        /*,CAST(ag1.approvedate AS DATETIME) +
            CAST(
                TRY_CAST(
                    RIGHT('0' + LEFT(RIGHT('0000' + CAST(ag1.approvetime AS VARCHAR), 4), 2), 2) + ':' +
                    RIGHT(RIGHT('0000' + CAST(ag1.approvetime AS VARCHAR), 2), 2) + ':00'
                    AS DATETIME
                ) AS DATETIME
            ) AS approval_date*/
        ,DATEADD(
        MINUTE,
        CAST(SUBSTRING(REPLACE(ag1.approvetime, ':', ''), 3, 2) AS INT) - DATEPART(MINUTE, ag1.approvedate),
        DATEADD(
            HOUR,
            CAST(LEFT(REPLACE(ag1.approvetime, ':', ''), 2) AS INT) - DATEPART(HOUR, ag1.approvedate),
            ag1.createdate
        )
        ) AS approval_date
        ,(
                        SELECT MAX(v.dt)
                        FROM (VALUES
                            (d1.lastmoddatetime),
                            (ISNULL(a1.lastmoddatetime, 19500101.000000)),
                            (ISNULL(ag1.lastmoddatetime, 19500101.000000)),
                            (ISNULL(au1.lastmoddatetime, 19500101.000000)),
                            (ISNULL(up1.lastmoddatetime, 19500101.000000))
                        ) AS v(dt)
                    ) AS lastmoddatetime
        FROM HBLive.rems.detail d1
            INNER JOIN HBLive.rems.company c1 
                ON d1.compcode = c1.compcode
            INNER JOIN HBLive.rems.division v1 
                ON d1.compcode = v1.compcode AND  d1.divcode = v1.divcode
            INNER JOIN HBLive.rems.account a1
                ON d1.acctcode = a1.acctcode AND 'MAST' = a1.mastercode
            INNER JOIN HBLive.rems.cdaccount ca1
                ON d1.acctcode = ca1.sourceacctcode AND 'EXRP' = ca1.targetmastercode AND 'MAST' = ca1.sourcemastercode
            INNER JOIN HBLive.rems.account a2 
                ON ca1.targetacctcode = a2.acctcode AND 'EXRP' = a2.mastercode
            INNER JOIN HBLive.rems.auditgroup ag1  
                ON d1.groupno = ag1.groupno
            INNER JOIN HBLive.rems.auditunit au1
                ON d1.groupno = au1.groupno AND d1.unitno = au1.unitno
            LEFT JOIN transform.fiscal_period dp1 ON          --added
                dp1.company_code = d1.compcode
                AND dp1.is_active = 'Y'
                AND dp1.is_closed = 1
                AND dp1.fiscal_year = YEAR(d1.postingdate)
                AND dp1.period = MONTH(d1.postingdate)
                --AND dp1.effective_start_date < DATEADD(day,-1,GETDATE())
                AND @LoadType <> 'FULL'
            LEFT JOIN HBLive.rems.uprofile up1  
                ON up1.operator = ag1.operator
            LEFT JOIN HBLive.rems.uprofile aup1 
                ON aup1.operator = ag1.approval 
        WHERE d1.cash = 0
            AND dp1.period_id IS NULL
            ) fact_general_ledger 
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
            @audit_type = 'STEP',
            @audit_id = @step_audit_id,
            @status = 'SUCCESS',
            @records_affected = @records_affected;
        --*************************--

        SET @current_step += 1;

        --------------------------
        -- STEP 2: Load PREP_01 --
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
        IF OBJECT_ID('tempdb..#PREP_02_fact_general_ledger') IS NOT NULL DROP TABLE #PREP_02_fact_general_ledger;

        SELECT
            src.*,
            CONVERT(VARCHAR(64), HASHBYTES('SHA2_256',
            CONCAT(
				ISNULL(src.gl_detail_id, ''),'~',
				ISNULL(TRIM(src.group_number), ''),'~',
				ISNULL(TRIM(src.unit_number), ''),'~',
				ISNULL(CAST(src.transaction_number AS VARCHAR), ''),'~',
				ISNULL(TRIM(src.company_code), ''),'~',
				ISNULL(TRIM(src.division_code), ''),'~',
				ISNULL(TRIM(src.target_acct_code), ''),'~',
				ISNULL(TRIM(src.target_acct_name), ''),'~',
				ISNULL(TRIM(src.source_acct_code), ''),'~',
				ISNULL(TRIM(src.source_acct_name), ''),'~',
				ISNULL(CAST(src.posting_date AS VARCHAR), ''),'~',
				ISNULL(TRIM(src.memo_1), ''),'~',
				ISNULL(TRIM(src.memo_2), ''),'~',
				ISNULL(CAST(src.amount AS VARCHAR), ''),'~',
				ISNULL(TRIM(src.lot_id), ''),'~',
				ISNULL(TRIM(src.major_code), ''),'~',
				ISNULL(TRIM(src.minor_code), ''),'~',
				ISNULL(TRIM(src.program_code), ''),'~',
				ISNULL(TRIM(src.source_program_code), ''),'~',
				ISNULL(TRIM(src.gl_created_by), ''),'~',
				ISNULL(CAST(src.gl_created_date AS VARCHAR), ''),'~',
				ISNULL(TRIM(src.approved_by), ''),'~',
				ISNULL(CAST(src.approval_date AS VARCHAR), '')
                )
            ), 2) AS record_hash_key,
            --@current_datetime AS effective_start_date,
            @current_datetime AS created_date,
            @CreatedBy AS created_by,
            @JobRunId AS created_job_run_id
        INTO #PREP_02_fact_general_ledger    
        FROM #PREP_01_fact_general_ledger src

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
        FROM transform.general_ledger_det tgt
        JOIN HBLive.rems.detail src
            ON CONCAT(src.groupno,'_',src.unitno,'_',src.transno) = tgt.gl_detail_id
        WHERE CONCAT(src.groupno,'_',src.unitno,'_',src.transno) IS NULL;

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
        FROM transform.general_ledger_det tgt
        JOIN #PREP_02_fact_general_ledger src
            ON src.gl_detail_id = tgt.gl_detail_id
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
        INSERT INTO transform.general_ledger_det (
            general_ledger_guid, gl_detail_id, group_number, unit_number, transaction_number, company_code,
            division_code, target_acct_code, target_acct_name, source_acct_code, 
            source_acct_name, posting_date, memo_1, memo_2, amount, lot_id, major_code,
            minor_code, program_code, source_program_code, gl_created_by, gl_created_date, 
            approved_by, approval_date, lastmoddatetime,
            /*effective_start_date, effective_end_date, is_active, is_deleted,*/
            created_date, created_by, created_job_run_id, record_hash_key
        )
        SELECT
            CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))) AS general_ledger_guid,
            src.gl_detail_id, src.group_number, src.unit_number, src.transaction_number, src.company_code, src.
            division_code, src.target_acct_code, src.target_acct_name, src.source_acct_code, src.
            source_acct_name, src.posting_date, src.memo_1, src.memo_2, src.amount, src.lot_id, src.major_code, src.
            minor_code, src.program_code, src.source_program_code, src.gl_created_by, src.gl_created_date, 
			src.approved_by, src.approval_date, src.lastmoddatetime,
            /*src.effective_start_date, @end_date, 'Y', 'N',*/
            src.created_date, src.created_by, src.created_job_run_id, src.record_hash_key
        FROM #PREP_02_fact_general_ledger src
        LEFT JOIN transform.general_ledger_det tgt
          ON src.gl_detail_id = tgt.gl_detail_id /*AND tgt.is_active = 'Y'*/
        WHERE tgt.gl_detail_id IS NULL OR tgt.record_hash_key <> src.record_hash_key;

 
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

        SELECT @total_record_count = count(general_ledger_guid) FROM transform.general_ledger_det;

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
