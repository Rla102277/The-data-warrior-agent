/*
*******************************************************************************************************************************************************************************************************
    OBJECT NAME    : SP_LOAD_DIM_SALE_TRANSFER
    CREATED BY     : Akshaya Dhanraj
    CREATED ON     : 27/05/2025
    PURPOSE        : Stored procedure for loading dimension tables
    INPUT PARAMS   : JobRunId,MaxDate,LoadType
    OUT PARAMS     : BOOLEAN
    EXEC Statement : EXEC dbo.sp_load_dim_sale_transfer(<JobRunId>, <MaxDate>, <LoadType>);
*******************************************************************************************************************************************************************************************************
*/
CREATE       PROCEDURE dbo.sp_load_dim_sale_transfer

    @CreatedBy    VARCHAR(100) = 'GB_user',
    @JobRunId     VARCHAR(100),
    @LoadType     VARCHAR(20) = '',
    @AuditId      VARCHAR(100) = '',
    @OrchestratorAuditId VARCHAR(100)  = ''

AS
BEGIN

    -- Declare & Define Last Modified Datetime , Audit Id & Load Type --
    --****************************************************************--

    DECLARE @pipeline_audit_id VARCHAR(100) = @AuditId;

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
            @audit_id         = @audit_id,
            @orchestrator_audit_id = @orchestrator_audit_id,
            @pipeline_audit_id = @pipeline_audit_id,
            @audit_type       = 'SP',
            @pipeline_run_id  = @JobRunId,
            @procedure_name   = 'sp_load_dim_sale_transfer',
            @load_type        = @LoadType,
            @max_date_time    = '',
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
        IF OBJECT_ID('tempdb..#PREP_01_dim_sale_transfer') IS NOT NULL DROP TABLE #PREP_01_dim_sale_transfer;

        SELECT 
        	selection_id
        	,ounitcode
        	,projcode
        	,i_lotno
        	,sd_model_id
        	,prospect_id
        	,sale_or_cancel
        	,sale_or_cancel_date
        	,sale_or_cancel_process_time
        	,cancel_reason_code
        	,ROW_NUMBER() OVER(PARTITION BY projcode, prospect_id ORDER BY sale_or_cancel_process_time) AS sale_or_cancel_seq
        INTO #SalesCancelSequence
        FROM (
            SELECT
        		bs.SelectionID AS selection_id
        		,p.ounitcode
        		,p.projcode 
        		,i_LotNo AS i_lotno
        		,bs.SDModelID AS sd_model_id
        		,bs.ProspectID AS prospect_id
        		,'Sale' AS sale_or_cancel
        		,bs.ContractApprDate AS sale_or_cancel_date
        		,bs.ApproveTimeStamp AS sale_or_cancel_process_time
        		,bs.CancelReasonCode AS cancel_reason_code
        	FROM SPLive.dbo.BuyerSelections bs
        		INNER JOIN HBLive.rems.project p  ON
        			p.projid = bs.i_ProjID
        	WHERE ContractApprDate IS NOT NULL

            UNION ALL

            SELECT
        		bc.SelectionID AS selection_id
        		,p.ounitcode
        		,p.projcode 
        		,i_LotNo AS i_lotno
        		,bc.SDModelID AS sd_model_id
        		,bc.ProspectID AS prospect_id
                ,'Cancel' AS sale_or_cancel
                ,bc.CancelDate AS sale_or_cancel_date
                ,bc.CancelTimeStamp AS sale_or_cancel_process_time
        		,bc.CancelReasonCode AS cancel_reason_code
        	FROM SPLive.dbo.BuyerCancels bc
        		INNER JOIN HBLive.rems.project p ON
        			p.projid = bc.i_ProjID
        	WHERE CancelDate IS NOT NULL
        	) SalesAndCancels
        ORDER BY prospect_id, sale_or_cancel_seq

        UPDATE ReversedCancels
        		SET ReversedCancels.sale_or_cancel_seq = ReversedCancels.sale_or_cancel_seq - 1
        	FROM #SalesCancelSequence ReversedCancels
        	INNER JOIN #SalesCancelSequence NewSelection ON ReversedCancels.ounitcode = NewSelection.ounitcode
        		AND ReversedCancels.projcode = NewSelection.projcode
        		AND ReversedCancels.prospect_id = NewSelection.prospect_id
        		AND ReversedCancels.selection_id <> NewSelection.selection_id
        		AND NewSelection.sale_or_cancel = 'Sale'
        		AND (ReversedCancels.sale_or_cancel_seq - 1) = NewSelection.sale_or_cancel_seq
        		AND DATEDIFF(dd, NewSelection.sale_or_cancel_process_time, ReversedCancels.sale_or_cancel_process_time) < 5
        		AND MONTH(NewSelection.sale_or_cancel_process_time) = MONTH(ReversedCancels.sale_or_cancel_process_time)
        	WHERE ReversedCancels.sale_or_cancel = 'Cancel'
        		AND ReversedCancels.cancel_reason_code IN ('CR10','CR12')


        UPDATE NewSelection
        	SET NewSelection.sale_or_cancel_seq = NewSelection.sale_or_cancel_seq + 1
        FROM #SalesCancelSequence NewSelection
        INNER JOIN #SalesCancelSequence ReversedCancels ON ReversedCancels.ounitcode = NewSelection.ounitcode
        	AND ReversedCancels.projcode = NewSelection.projcode
        	AND ReversedCancels.prospect_id = NewSelection.prospect_id
        	AND ReversedCancels.selection_id <> NewSelection.selection_id
        	AND NewSelection.sale_or_cancel = 'Sale'
        	AND ReversedCancels.sale_or_cancel_seq = NewSelection.sale_or_cancel_seq
        	AND DATEDIFF(dd, NewSelection.sale_or_cancel_process_time, ReversedCancels.sale_or_cancel_process_time) < 5
        	AND MONTH(NewSelection.sale_or_cancel_process_time) = MONTH(ReversedCancels.sale_or_cancel_process_time)
        WHERE ReversedCancels.sale_or_cancel = 'Cancel'
        	AND ReversedCancels.cancel_reason_code IN ('CR10','CR12')
        SELECT 
            CONCAT(transfer_from_selection_id , '_' ,transfer_to_selection_id) AS transfer_id
        	,*
        INTO #PREP_01_dim_sale_transfer    
        FROM (
        SELECT  
                bc.SelectionID AS transfer_from_selection_id
        		,SaleCancel.selection_id AS transfer_to_selection_id
        		,SaleCancel.sale_or_cancel_date AS transfer_date
        		,PriorCancel.cancel_reason_code AS reason_code
        		,cr.Descr AS reason_description

        	FROM #SalesCancelSequence SaleCancel 
        	INNER JOIN #SalesCancelSequence PriorCancel ON SaleCancel.prospect_id = PriorCancel.prospect_id
        		AND SaleCancel.ProjCode = PriorCancel.ProjCode
        		AND SaleCancel.selection_id <> PriorCancel.selection_id
        		AND (SaleCancel.sale_or_cancel_seq - 1) = PriorCancel.sale_or_cancel_seq
        		AND PriorCancel.sale_or_cancel = 'Cancel'
        		AND PriorCancel.cancel_reason_code IN ('CR10','CR12')
        		AND MONTH(SaleCancel.sale_or_cancel_date) = MONTH(PriorCancel.sale_or_cancel_date)
        		AND YEAR(SaleCancel.sale_or_cancel_date) = YEAR(PriorCancel.sale_or_cancel_date)
        	INNER JOIN SPLive.dbo.BuyerCancels bc ON PriorCancel.selection_id = bc.SelectionID
        	INNER JOIN SPLive.dbo.m_CancelReasons cr ON
        		cr.CancelReasonCode = PriorCancel.cancel_reason_code
        	WHERE SaleCancel.sale_or_cancel = 'Sale'
        ) dim_sale_transfer ;

        DROP TABLE #SalesCancelSequence;   

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
        IF OBJECT_ID('tempdb..#PREP_02_dim_sale_transfer') IS NOT NULL DROP TABLE #PREP_02_dim_sale_transfer;

        SELECT
            src.*,
            CONVERT(VARCHAR(64), HASHBYTES('SHA2_256',
            CONCAT(
                ISNULL(CAST(src.transfer_from_selection_id AS VARCHAR), ''), '~',
                ISNULL(CAST(src.transfer_to_selection_id AS VARCHAR), ''), '~',
                ISNULL(CAST(src.transfer_date  AS VARCHAR), ''), '~',
                ISNULL(TRIM(src.reason_code), ''), '~',
                ISNULL(TRIM(src.reason_description), '')
                )
            ), 2) AS record_hash_key,
            @current_datetime AS effective_start_date,
            @current_datetime AS created_date,
            @CreatedBy AS created_by,
            @JobRunId AS created_job_run_id
        INTO #PREP_02_dim_sale_transfer    
        FROM #PREP_01_dim_sale_transfer src
        LEFT JOIN dbo.dim_sale_transfer tgt
          ON src.transfer_id = tgt.transfer_id AND tgt.is_active = 'Y';

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
        -- STEP 3: Truncate target table before load --
        -------------------------------------------------

        -- Start Step3 Run Audit --
        --*************************--

        EXEC control.sp_audit_start 
            @audit_id         = @audit_id,
            @audit_type       = 'STEP',
            @step_number      = @current_step,
            @step_name        = 'Truncate and Load Records',
            @step_description = 'Truncate the table before loading',
            @return_id        = @step_audit_id OUTPUT;
        --*************************--

        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Truncate and Load Records';

        TRUNCATE TABLE dbo.dim_sale_transfer;

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

        ---------------------------------------
        --- STEP 4. Insert rows ---
        ---------------------------------------

        -- Start Step4 Run Audit --
        --*************************--

        EXEC control.sp_audit_start 
            @audit_id         = @audit_id,
            @audit_type       = 'STEP',
            @step_number      = @current_step,
            @step_name        = 'Insert Records',
            @step_description = 'Insert records into target table',
            @return_id        = @step_audit_id OUTPUT;
        --*************************--

        PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Insert Records';

        INSERT INTO dbo.dim_sale_transfer (
            sale_transfer_guid,
            transfer_id,
            transfer_from_selection_id,
            transfer_to_selection_id,
            transfer_date,
            reason_code,
            reason_description,
            effective_start_date, effective_end_date, is_active,
            created_date, created_by, created_job_run_id, record_hash_key
        )
        SELECT
            CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))),
            src.transfer_id,
            src.transfer_from_selection_id,
            src.transfer_to_selection_id,
            src.transfer_date,
            src.reason_code,
            src.reason_description,
            src.effective_start_date, @end_date, 'Y',
            src.created_date, src.created_by, src.created_job_run_id, src.record_hash_key
        FROM #PREP_02_dim_sale_transfer src;

        SET @records_affected = @@ROWCOUNT;
        SET @total_inserted = @records_affected;

        -- End Step4 Run Audit --
        --*************************--
        EXEC control.sp_audit_end 
            @audit_type        = 'STEP',
            @audit_id          = @step_audit_id,
            @status            = 'SUCCESS',
            @records_affected  = @records_affected;
        --*************************--

        SELECT @total_record_count = count(sale_transfer_guid) FROM EDW_Silver.dbo.dim_sale_transfer WHERE is_active = 'Y';

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
