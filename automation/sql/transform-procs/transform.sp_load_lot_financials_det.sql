/*
*******************************************************************************************************************************************************************************************************
    OBJECT NAME    : SP_LOAD_FACT_LOT_FINANCIALS
    CREATED BY     : Kamalesh Radhakrishnan
    CREATED ON     : 11/07/2025
    PURPOSE        : Stored procedure for loading fact tables
    INPUT PARAMS   : JobRunId,MaxDateTime,LoadType
    OUT PARAMS     : BOOLEAN
    EXEC Statement : EXEC transform.sp_load_lot_financials_det(<JobRunId>, <MaxDate>, <LoadType>);
*******************************************************************************************************************************************************************************************************
*/

CREATE     PROCEDURE transform.sp_load_lot_financials_det
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
        TRUNCATE TABLE transform.lot_financials_det;
        PRINT 'Load type is FULL. transform.lot_financials_det table truncated.'
    END
    ELSE IF @LoadType = ''
    BEGIN
        SELECT @MaxDateTime = ISNULL(CONVERT(VARCHAR(15), MAX(lastmoddatetime)),'Table is empty') FROM transform.lot_financials_det;
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
            @procedure_name = 'sp_load_lot_financials_det',
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
        IF OBJECT_ID('tempdb..#PREP_00_fact_lot_financials') IS NOT NULL DROP TABLE #PREP_00_fact_lot_financials;
        IF OBJECT_ID('tempdb..#PREP_01_fact_lot_financials') IS NOT NULL DROP TABLE #PREP_01_fact_lot_financials;
        
        WITH ModelPrices AS (
            SELECT 
                SDModelID,
                UnitPrice,
                CAST(FORMAT(EffectiveDate, 'yyyyMMdd') + '.' + FORMAT(EffectiveDate, 'HHmmss') AS DECIMAL(17,6)) AS lastmoddatetime,
                N = ROW_NUMBER() OVER(PARTITION BY SDModelID ORDER BY EffectiveDate DESC)
            FROM [SPLive].[dbo].[SDModelPrices]
            WHERE EffectiveDate <= GETDATE()
        ),
        ModelPricesFiltered AS (
            SELECT * FROM ModelPrices WHERE N = 1
        ),
        SaleDataValues AS (
            SELECT 
                jobphase.projid + '_' + jobphase.phase AS lot_id,
                CAST(CASE WHEN JobSales.contractdate IS NULL THEN MP.UnitPrice ELSE JobSales.basemodelprice END AS DECIMAL(17,2)) AS basemodelprice,
                CAST(CASE WHEN JobSales.contractdate IS NULL THEN SDLots.LotPremium ELSE JobSales.baselotpremium END AS DECIMAL(17,2)) AS baselotpremium,
                CAST(CASE WHEN JobSales.contractdate IS NULL THEN SDLots.AdjLotPremium ELSE JobSales.adjlotpremium END AS DECIMAL(17,2)) AS adjlotpremium,
                CAST(CASE WHEN JobSales.contractdate IS NULL THEN SDLots.AdjLotPrice ELSE JobSales.adjlotprice END AS DECIMAL(17,2)) AS adjlotprice,
                CAST(CASE WHEN JobSales.contractdate IS NULL THEN SDLots.AdjModelPrice ELSE JobSales.adjmodelprice END AS DECIMAL(17,2)) AS adjmodelprice,
                CAST(CASE WHEN JobSales.contractdate IS NULL THEN SDLots.AdjMortgage ELSE JobSales.adjmortgincon END AS DECIMAL(17,2)) AS adjmortgincon,
                CAST(
                    ISNULL(JobSalesInfo.firstagentcomm, 0) +
                    ISNULL(JobSalesInfo.secondagentcomm, 0) +
                    ISNULL(JobSalesInfo.thirdagentcomm, 0) +
                    ISNULL(JobSalesInfo.fourthagentcomm, 0) +
                    ISNULL(JobSalesInfo.fifthagentcomm, 0)
                AS DECIMAL(17,2)) AS agentcomm,
                CAST(ISNULL(JobSalesInfo.agencycomm, 0) AS DECIMAL(17,2)) AS reagentcomm,
                (
                    SELECT MAX(v.dt)
                    FROM ( VALUES
                        (jobphase.lastmoddatetime),
                        (ISNULL (JobSales.lastmoddatetime, 19500101.000000)),
                        (ISNULL (JobSalesInfo.lastmoddatetime, 19500101.000000)),
                        (ISNULL (CAST(FORMAT(SDLots.LastModified, 'yyyyMMdd') + '.' + FORMAT(SDLots.LastModified, 'HHmmss') AS DECIMAL(17,6)), 19500101.000000)),
                        (ISNULL (MP.lastmoddatetime, 19500101.000000))
                    ) AS v (dt)
                ) AS lastmoddatetime
            FROM HBLive.rems.jobphase jobphase
            INNER JOIN HBLive.rems.jobsales JobSales 
                ON JobSales.projid = jobphase.projid AND JobSales.phase = jobphase.phase
            INNER JOIN HBLive.rems.jobsalesinfo JobSalesInfo 
                ON JobSalesInfo.projid = jobphase.projid
                AND JobSalesInfo.phase = jobphase.phase
            LEFT JOIN SPLive.dbo.SDLots SDLots 
                ON SDLots.LotNo = jobphase.phase AND SDLots.i_ProjID = jobphase.projid
            LEFT JOIN ModelPricesFiltered MP 
                ON MP.SDModelID = SDLots.SDModelID
        ),
        SalesFinancials AS (
            SELECT 
                lot_id,
                CAST(CASE colname 
                    WHEN 'basemodelprice' THEN '9001'
                    WHEN 'baselotpremium' THEN '9005'
                    WHEN 'adjlotpremium' THEN '9015'
                    WHEN 'adjlotprice' THEN '9016'
                    WHEN 'adjmodelprice' THEN '9011'
                    WHEN 'adjmortgincon' THEN '9117'
                    WHEN 'agentcomm' THEN '9112'
                    WHEN 'reagentcomm' THEN '9114'
                END AS VARCHAR) AS major_code,
                CAST(CASE colname 
                    WHEN 'basemodelprice' THEN '90'
                    WHEN 'baselotpremium' THEN '90'
                    WHEN 'adjlotpremium' THEN '95'
                    WHEN 'adjlotprice' THEN '95'
                    WHEN 'adjmodelprice' THEN '95'
                    WHEN 'adjmortgincon' THEN '91'
                    WHEN 'agentcomm' THEN '91'
                    WHEN 'reagentcomm' THEN '91'
                END AS VARCHAR) AS minor_code,
                'S' AS latest_est_calc_method,
                'S' AS latest_est_method_used,
                0 AS anchor_estimate,
                amount AS latest_est_amount,
                lastmoddatetime
            FROM SaleDataValues
            UNPIVOT (
                amount FOR colname IN (
                    basemodelprice,
                    baselotpremium,
                    adjlotpremium,
                    adjlotprice,
                    adjmodelprice,
                    adjmortgincon,
                    agentcomm,
                    reagentcomm
                )
            ) AS Unpivoted
        ),
        SalesFinancialsFull AS (
            SELECT 
                Lots.projid +'_'+ Lots.phase AS lot_id,
                JobSalesExti.majorcode AS major_code,
                JobSalesExti.minorcode AS minor_code,
                'S' AS latest_est_calc_method,
                'S' AS latest_est_method_used,
                0 AS anchor_estimate,
                SUM(JobSalesExti.amount) AS latest_est_amount,
                (
                    SELECT MAX(v.dt)
                    FROM ( VALUES
                        (Lots.lastmoddatetime),
                        (ISNULL (JobSalesExti.lastmoddatetime, 19500101.000000))
                    ) AS v (dt)
                ) AS lastmoddatetime
            FROM HBLive.rems.jobphase Lots
                INNER JOIN HBLive.rems.jobsalesexti JobSalesExti ON JobSalesExti.projid = Lots.projid
                    AND JobSalesExti.phase = Lots.phase
                WHERE JobSalesExti.amount <> 0.00
                    AND JobSalesExti.cancel = 0
                    AND JobSalesExti.buyerapprv = 1
                    AND UPPER(JobSalesExti.prodcode) <> '0000BASE'
                GROUP BY Lots.projid
                        ,Lots.phase
                        ,JobSalesExti.majorcode
                        ,JobSalesExti.minorcode
                        ,Lots.lastmoddatetime
                        ,JobSalesExti.lastmoddatetime

            UNION ALL
            SELECT * FROM SalesFinancials
        ),
        FactLotFinancials AS (
            SELECT 
                lot_financials_id,
                lot_id,
                major_code,
                minor_code,
                latest_est_calc_method,
                latest_est_method_used,
                anchor_estimate,
                latest_est_amount,
                SUM(gl_amount) AS gl_amount,
                sgm_type,
                sgm_type_description,
                MAX(lastmoddatetime) as lastmoddatetime
            FROM (
                SELECT
                    CONCAT(jp.projid, '_', jp.phase, '_', jp.majorcode, '_', jp.minorcode) AS lot_financials_id,
                    CONCAT(jp.projid, '_', jp.phase) AS lot_id,
                    jp.majorcode AS major_code,
                    jp.minorcode AS minor_code,
                    jp.highestofvalues AS latest_est_calc_method,
                    jp.valueusedinprojn AS latest_est_method_used,
                    jp.anchorestimate AS anchor_estimate,
                    jp.projdamt AS latest_est_amount,
                    COALESCE(fgl.amount,0.00) AS gl_amount,
                    dsm.sgm_type AS sgm_type,
                    dsm.description AS sgm_type_description,
                    (
                        SELECT MAX(v.dt)
                        FROM ( VALUES
                            (jp.lastmoddatetime),
                            (ISNULL (fgl.lastmoddatetime, 19500101.000000)),
                            (ISNULL (dsm.lastmoddatetime, 19500101.000000))
                        ) AS v (dt)
                    ) AS lastmoddatetime
                FROM
                    HBLive.rems.jobprojn jp 
                    LEFT JOIN (
                                SELECT lot_id
                                    ,major_code
                                    ,minor_code
                                    ,SUM(amount) amount
                                    ,MAX(lastmoddatetime) lastmoddatetime
                                FROM transform.general_ledger_det 
                                GROUP BY lot_id,major_code,minor_code
                            ) AS fgl ON CONCAT(jp.projid, '_', jp.phase) = fgl.lot_id AND fgl.major_code = jp.majorcode AND fgl.minor_code = jp.minorcode
                    LEFT JOIN transform.sales_gross_margin_map dsm ON jp.majorcode = dsm.major_code AND jp.minorcode = dsm.minor_code AND dsm.is_active = 'Y'
                WHERE dsm.sgm_type NOT IN ('3020','3021','3022','3023','3030','3040','3590','3591','9998') 
            ) AS sub
            GROUP BY
                lot_financials_id, lot_id, major_code, minor_code, latest_est_calc_method,
                latest_est_method_used, anchor_estimate, latest_est_amount, sgm_type, sgm_type_description
        ),
        SalesFinacialsAggregate AS (
            SELECT CONCAT(S.lot_id, '_', S.major_code, '_', S.minor_code) AS lot_financials_id,
                    S.lot_id,
                    S.major_code,
                    S.minor_code,
                    S.latest_est_calc_method,
                    S.latest_est_method_used,
                    SUM(S.anchor_estimate) AS anchor_estimate,
                    SUM(S.latest_est_amount) AS latest_est_amount,
                    ABS(SUM(G.amount)) gl_amount,
                    M.sgm_type,
                    M.description,
                    MAX(S.lastmoddatetime) AS lastmoddatetime
            FROM SalesFinancialsFull S
                LEFT JOIN transform.sales_gross_margin_map M ON
                    M.major_code = S.major_code
                    AND M.minor_code = S.minor_code
                    AND M.sgm_active = 1
                    AND M.is_active = 'Y'
                LEFT JOIN transform.general_ledger_det G ON
                    G.lot_id = S.lot_id 
                    AND G.major_code = S.major_code
                    AND G.minor_code = S.minor_code
            GROUP BY 
                S.lot_id,
                S.major_code,
                S.minor_code,
                S.latest_est_calc_method,
                S.latest_est_method_used,
                M.sgm_type,
                M.description
        ),
        FactLotFinancialsAddedRevenue AS (
            SELECT * FROM FactLotFinancials
            UNION ALL
            SELECT * FROM SalesFinacialsAggregate
        )
        SELECT * INTO #PREP_00_fact_lot_financials FROM FactLotFinancialsAddedRevenue;

        SELECT * 
        INTO #PREP_01_fact_lot_financials
        FROM #PREP_00_fact_lot_financials
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
        IF OBJECT_ID('tempdb..#PREP_02_fact_lot_financials') IS NOT NULL DROP TABLE #PREP_02_fact_lot_financials;
        SELECT 
            src.*,
            @current_datetime AS created_date,
            @CreatedBy AS created_by,
            @JobRunId AS created_job_run_id,
            CONVERT(
                VARCHAR(64), 
                HASHBYTES('SHA2_256',
                    CONCAT(
                        ISNULL(TRIM(src.lot_id), ''), '~',
                        ISNULL(TRIM(src.major_code), ''), '~',
                        ISNULL(TRIM(src.minor_code), ''), '~',
                        ISNULL(TRIM(src.latest_est_calc_method), ''), '~',
                        ISNULL(TRIM(src.latest_est_method_used), ''), '~',
                        ISNULL(CONVERT(VARCHAR, src.anchor_estimate), ''), '~',
                        ISNULL(CONVERT(VARCHAR, src.latest_est_amount), ''), '~',
                        ISNULL(CONVERT(VARCHAR, src.gl_amount), ''), '~',
                        ISNULL(TRIM(src.sgm_type), ''), '~',
                        ISNULL(TRIM(src.sgm_type_description), '')
                    ) 
                ), 
                2
            ) as record_hash_key
        INTO #PREP_02_fact_lot_financials 
        FROM #PREP_01_fact_lot_financials as src
        LEFT JOIN transform.lot_financials_det tgt
            ON src.lot_financials_id = tgt.lot_financials_id;

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
        FROM transform.lot_financials_det tgt
        JOIN #PREP_00_fact_lot_financials src
            ON src.lot_financials_id = tgt.lot_financials_id
        WHERE src.lot_financials_id IS NULL;

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
        FROM transform.lot_financials_det tgt
        JOIN #PREP_02_fact_lot_financials src
            ON src.lot_financials_id = tgt.lot_financials_id
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
        INSERT INTO transform.lot_financials_det (
            lot_financials_guid, lot_financials_id, lot_id, major_code, minor_code, latest_est_calc_method, 
            latest_est_method_used, anchor_estimate, latest_est_amount,gl_amount,
            sgm_type, sgm_type_description, lastmoddatetime, created_date, record_hash_key, created_by, created_job_run_id
        )
        SELECT
            CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))) AS lot_financials_guid,
            src.lot_financials_id,
            src.lot_id,
            src.major_code,
            src.minor_code,
            src.latest_est_calc_method,
            src.latest_est_method_used,
            src.anchor_estimate,
            src.latest_est_amount,
            src.gl_amount,
            src.sgm_type,
            src.sgm_type_description,
            src.lastmoddatetime,
            src.created_date,
            src.record_hash_key,
            src.created_by,
            src.created_job_run_id
        FROM #PREP_02_fact_lot_financials src
        LEFT JOIN transform.lot_financials_det tgt
            ON src.lot_financials_id = tgt.lot_financials_id
        WHERE 
        tgt.lot_financials_id IS NULL;
 

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

        SELECT @total_record_count = count(lot_financials_guid) FROM transform.lot_financials_det;

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
