/*
*******************************************************************************************************************************************************************************************************
    OBJECT NAME    : SP_LOAD_DIM_SALE
    CREATED BY     : Akshaya Dhanraj
    CREATED ON     : 27/05/2025
    PURPOSE        : Stored procedure for loading dimension tables
    INPUT PARAMS   : JobRunId,MaxDate,LoadType
    OUT PARAMS     : BOOLEAN
    EXEC Statement : EXEC dbo.sp_load_dim_sale(<JobRunId>, <MaxDate>, <LoadType>);
*******************************************************************************************************************************************************************************************************
*/
CREATE       PROCEDURE dbo.sp_load_dim_sale

    @CreatedBy    VARCHAR(100) = 'GB_user',
    @JobRunId     VARCHAR(100),
    @LoadType     VARCHAR(20) = '',
    @AuditId      VARCHAR(100) = '',
    @OrchestratorAuditId VARCHAR(100)  = ''

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
        SELECT @MaxDateTime = ISNULL(CONVERT(VARCHAR(15), MAX(lastmoddatetime)),'Table is empty') FROM dbo.dim_sale;
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
            @procedure_name   = 'sp_load_dim_sale',
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
        IF OBJECT_ID('tempdb..#PREP_01_dim_sale') IS NOT NULL DROP TABLE #PREP_01_dim_sale;

        WITH 
    CTE_AddFloorArea AS (
            SELECT JS.i_recid AS SelectionID,
                SUM(PP.addfloorarea) AS AddFloorArea
            FROM HBLive.rems.jobphase JP
                INNER JOIN HBLive.rems.jobsales JS ON
                    JS.projid = JP.projid
                    AND JS.phase = JP.phase
                INNER JOIN HBLive.rems.jobsalesexti JSI ON
                    JS.projid = JSI.projid
                    AND JS.phase = JSI.phase
                INNER JOIN HBLive.rems.slproduct PL ON
                    PL.prodlist = JSI.listcode
                    AND PL.prodcode = JSI.prodcode
                INNER JOIN HBLive.rems.slprodprice PP ON
                    PP.projid = JP.projid
                    AND PP.prodid = PL.prodid
                    AND ((PP.model = JP.model AND PP.elev = JP.elev) OR PP.model = '*' )
            WHERE PP.addfloorarea <> 0 AND PP.addfloorarea IS NOT NULL
                AND ISNUMERIC(JS.i_recid) = 1
            GROUP BY JS.i_recid
        ),
        CTE_BaseFloorArea AS (
            SELECT 
                JS.i_recid AS SelectionID,
                BaseFloorArea = SUM(COALESCE(JM.area,0))
            FROM HBLive.rems.jobphase JP
                INNER JOIN HBLive.rems.jobsales JS ON
                    JS.projid = JP.projid
                    AND JS.phase = JP.phase
                INNER JOIN HBLive.rems.jobmodel JM ON
                    JM.projid = JP.projid
                    AND JM.model = JP.model
                    AND JM.elev = JP.elev
            WHERE ISNUMERIC(JS.i_recid) = 1
            GROUP BY JS.i_recid
        ),
        CTE_SquareFootage AS (
            SELECT 
                B.SelectionID,
                Sqft = COALESCE(B.BaseFloorArea,0) + COALESCE(A.AddFloorArea,0)
            FROM CTE_BaseFloorArea B
                LEFT JOIN CTE_AddFloorArea A ON
                    A.SelectionID = B.SelectionID
        ),
        CTE_Contingencies AS (
            SELECT 
                bc.SelectionID,
                STRING_AGG(ct.Descr, ', ') AS ContingencyDescr,
                STRING_AGG(CONVERT(VARCHAR(20), bc.ExpiryDate, 110), ', ') AS ExpiryDate
            FROM SPLive.dbo.BuyerContingencies bc
            INNER JOIN SPLive.dbo.m_ContingencyTypes ct
                ON bc.ContingencyTypeID = ct.ContingencyTypeID
            WHERE bc.MetDate IS NULL
            AND ISNUMERIC(bc.SelectionID) = 1
            GROUP BY bc.SelectionID
        ),
        CTE_CoBuyersNames AS (
            SELECT 
                bc.SelectionID,
                STRING_AGG(CONCAT(pcb.FirstName, ' ', pcb.LastName), ', ') AS CoBuyerNames,
                STRING_AGG(pcb.HomeEmail, ', ') AS CoBuyerEmails
            FROM SPLive.dbo.BuyerCoBuyers bc
            INNER JOIN SPLive.dbo.ProspectCoBuyers pcb
                ON bc.CoBuyerID = pcb.CoBuyerID
            WHERE ISNUMERIC(bc.SelectionID) = 1
            GROUP BY bc.SelectionID
        ),
        CTE_DepositSummary AS (
            SELECT 
                SelectionID,
                SUM(DepositAmt) AS TotalDepositsDue,
                SUM(CASE WHEN ReturnPayment = 1 THEN 0 ELSE PaymentAmt END) AS DepositsPaid
            FROM SPLive.dbo.BuyerDeposits
            WHERE  ISNUMERIC(SelectionID) = 1
            GROUP BY SelectionID
        ),
        CTE_MaxContingencyExpiry AS (
            SELECT 
                SelectionID,
                MAX(ExpiryDate) AS MaxExpiryDate
            FROM SPLive.dbo.BuyerContingencies
            WHERE ISNUMERIC(SelectionID) = 1
            GROUP BY SelectionID
        )

        SELECT 
        *
        INTO #PREP_01_dim_sale

        FROM (
        SELECT 
            bs1.SelectionID AS sale_id
            ,jp1.projid AS project_id
            ,CONCAT(jp1.projid , '_' , jp1.phase) AS lot_id 
            ,jp1.phase AS lot_number
            ,CASE 
                WHEN js1.actualdateclosed IS NOT NULL THEN 'Closed'
                WHEN dst_from.transfer_from_selection_id IS NOT NULL THEN 'Transfer'
                WHEN bc1.CancelDate IS NOT NULL THEN 'Cancelled'
                WHEN bs1.ContractApprDate IS NOT NULL THEN 'Backlog'
                WHEN bs1.ContractSubmitDate IS NOT NULL THEN 'Pending Sale'
                ELSE 'Open'
            END AS sales_status
            ,CASE 
                WHEN dj1.start_date IS NULL OR dj1.start_date <= bs1.ContractApprDate THEN 'Spec' 
                ELSE 'TBB' 
            END AS sale_type
            ,jpa1.street
            ,jpa1.street2
            ,jpa1.suite
            ,jpa1.postal AS zip
            ,c1.cityname AS city
            ,c1.provcode AS state
            ,sf1.Sqft AS sqft
            ,cont1.ContingencyDescr AS contingency_descr
            ,mce1.MaxExpiryDate AS contingency_expiry
            ,CONCAT(p1.FirstName , ' ' , p1.LastName) AS buyer_name
            ,COALESCE(p1.HomeEmail,p1.WorkEmail) AS buyer_email
            ,p1.CellPhone AS buyer_cell_phone
            ,p1.HomePhone AS buyer_home_phone
            ,p1.BusinessPhone AS buyer_work_phone
            ,cbn1.CoBuyerNames AS cobuyer_names
            ,u1.FirstName + ' ' + u1.LastName AS sales_agent
            ,u1.Email AS sales_agent_email
            ,u1.CellPhone AS sales_agent_cell_phone
            ,u1.HomePhone AS sales_agent_home_phone
            ,u1.BusinessPhone AS sales_agent_work_phone
            ,ra1.FirstName + ' ' + ra1.LastName AS realtor_name
            ,ra1.Email AS realtor_email
            ,ra1.CellPhone AS realtor_cell_phone
            ,ra1.HomePhone AS realtor_home_phone
            ,ra1.BusinessPhone AS realtor_work_phone
            ,rag1.Name AS agency_name
            ,l1.Name AS lender
            ,CASE WHEN l1.LenderID IN (3861,2694,2629,2640,2641,2733) THEN 1 ELSE 0 END AS lender_preferred
            ,COALESCE(bs1.LoanOfficer, bc1.LoanOfficer) AS lender_contact
            ,CONCAT(lo1.FirstName , ' ' , lo1.LastName) AS loan_officer
            ,lo1.Email AS loan_officer_email
            ,lo1.Phone AS loan_officer_phone
            ,COALESCE(bs1.FinanceOption, bc1.FinanceOption) AS loan_type
            ,tc1.Name AS title_company
            ,ds1.TotalDepositsDue AS total_deposits_due
            ,ds1.DepositsPaid AS deposits_paid
            ,COALESCE(bs1.ContractDate, bc1.ContractDate) AS contract_date
            ,COALESCE(bs1.ContractSubmitDate, bc1.ContractSubmitDate) AS submit_date
            ,COALESCE(bs1.ContractApprDate, bc1.ContractApprDate) AS approved_date 
            ,COALESCE(bs1.ApproveTimeStamp, bc1.ApproveTimeStamp) AS approved_timestamp
            ,bc1.CancelDate AS cancel_date 
            ,bc1.CancelReasonCode AS cancel_code
            ,mcr1.Descr AS cancel_reason
            ,bc1.CancelTimeStamp AS cancel_timestamp
            ,CASE WHEN mce1.MaxExpiryDate > GETDATE() THEN 1 ELSE 0 END AS is_contingent
            ,CASE 
                WHEN dst_to.transfer_to_selection_id IS NOT NULL THEN 1 
                ELSE 0 
            END AS is_transfer_to
            ,dst_to.transfer_id AS transfer_to_id
            ,dst_to.transfer_date AS transfer_to_date
            ,CASE 
                WHEN dst_from.transfer_from_selection_id IS NOT NULL THEN 1 
                ELSE 0 
            END AS is_transfer_from
            ,dst_from.transfer_id AS transfer_from_id
            ,dst_from.transfer_date AS transfer_from_date
            ,(
                SELECT MAX(v.dt)
                FROM (VALUES
                    (CAST(CONVERT(CHAR(8), bs1.LastModified, 112) AS VARCHAR) + '.' +REPLACE(CONVERT(CHAR(8), bs1.LastModified, 108), ':', '')),
                    (CAST(CONVERT(CHAR(8), bc1.LastModified, 112) AS VARCHAR) + '.' +REPLACE(CONVERT(CHAR(8), bc1.LastModified, 108), ':', '')),
                    (ISNULL(jp1.lastmoddatetime, 19500101.000000)),
                    (ISNULL(js1.lastmoddatetime, 19500101.000000)),
                    (ISNULL(dj1.lastmoddatetime, 19500101.000000)),
                    (ISNULL(jpa1.lastmoddatetime, 19500101.000000)),
                    (ISNULL(c1.lastmoddatetime, 19500101.000000)),
                    (ISNULL((CAST(CONVERT(CHAR(8), p1.LastModified, 112) AS VARCHAR) + '.' +REPLACE(CONVERT(CHAR(8), p1.LastModified, 108), ':', '')), 19500101.000000)),
                    (ISNULL((CAST(CONVERT(CHAR(8), lo1.LastModified, 112) AS VARCHAR) + '.' +REPLACE(CONVERT(CHAR(8), lo1.LastModified, 108), ':', '')), 19500101.000000))
                ) AS v(dt)
            ) AS lastmoddatetime

        FROM SPLive.dbo.BuyerSelections bs1
        LEFT JOIN SPLive.dbo.BuyerCancels bc1 ON bc1.SelectionID = bs1.SelectionID
        INNER JOIN HBLive.rems.jobphase jp1 ON jp1.projid = bs1.i_ProjID AND jp1.phase = bs1.i_LotNo 
        LEFT JOIN HBLive.rems.jobsales js1 ON js1.projid = jp1.projid AND js1.phase = jp1.phase AND js1.i_recid = CAST(bs1.SelectionID AS VARCHAR(50)) --ADDED
        LEFT JOIN EDW_Silver.dbo.dim_sale_transfer dst_to ON dst_to.transfer_to_selection_id = bs1.SelectionID
        LEFT JOIN EDW_Silver.dbo.dim_sale_transfer dst_from ON dst_from.transfer_from_selection_id = bs1.SelectionID

        LEFT JOIN EDW_Silver.dbo.dim_job dj1 ON dj1.lot_id = CONCAT(jp1.projid , '_' , jp1.phase) AND dj1.is_active = 'Y' AND dj1.job_active = 1

        LEFT JOIN HBLive.rems.jobphaseaddr jpa1 ON jpa1.projid = bs1.i_ProjID AND jpa1.phase = bs1.i_LotNo
        
        LEFT JOIN HBLive.rems.city c1 ON jpa1.citycode = c1.citycode

        LEFT JOIN CTE_SquareFootage sf1 ON sf1.SelectionID = bs1.SelectionID

        LEFT JOIN CTE_Contingencies cont1 ON cont1.SelectionID = bs1.SelectionID

        INNER JOIN SPLive.dbo.Prospects p1 ON p1.ProspectID = bs1.ProspectID

        LEFT JOIN CTE_CoBuyersNames cbn1 ON cbn1.SelectionID = bs1.SelectionID

        LEFT JOIN SPLive.dbo.BuyerAgents ba1 ON ba1.SelectionID = bs1.SelectionID AND ba1.SeqNo = 1
        LEFT JOIN SPLive.dbo.Users u1 ON u1.UserID = ba1.UserID

        LEFT JOIN SPLive.dbo.BuyerREAgents bra1 ON bra1.SelectionID = bs1.SelectionID AND bra1.SeqNo = 1
        LEFT JOIN SPLive.dbo.REAgents ra1 ON ra1.REAgentID = bra1.REAgentID
        LEFT JOIN SPLive.dbo.REAgencies rag1 ON rag1.REAgencyID = bra1.REAgencyID

        LEFT JOIN SPLive.dbo.Lenders l1 ON l1.LenderID = bs1.LenderID

        LEFT JOIN SPLive.dbo.LoanOfficer lo1 ON lo1.LoanofficerID = bs1.LoanOfficerID

        LEFT JOIN SPLive.dbo.TitleCompanies tc1 ON tc1.TitleCompanyID = bs1.TitleCompanyID

        LEFT JOIN CTE_DepositSummary ds1 ON ds1.SelectionID = bs1.SelectionID

        LEFT JOIN SPLive.dbo.m_CancelReasons mcr1 ON mcr1.CancelReasonCode = bc1.CancelReasonCode

        LEFT JOIN CTE_MaxContingencyExpiry mce1 ON mce1.SelectionID = bs1.SelectionID ) dim_sale
        
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
        IF OBJECT_ID('tempdb..#PREP_02_dim_sale') IS NOT NULL DROP TABLE #PREP_02_dim_sale;

        SELECT
            src.*,
            CONVERT(VARCHAR(64), HASHBYTES('SHA2_256',
            CONCAT(
                ISNULL(TRIM(CAST(src.sale_id AS VARCHAR)), ''), '~',
                ISNULL(TRIM(src.project_id), ''), '~',
                ISNULL(TRIM(src.lot_id), ''), '~',
                ISNULL(TRIM(src.lot_number), ''), '~',
                ISNULL(TRIM(src.sales_status), ''), '~',
                ISNULL(TRIM(src.sale_type), ''), '~',
                ISNULL(TRIM(src.street), ''), '~',
                ISNULL(TRIM(src.street2), ''), '~',
                ISNULL(TRIM(src.suite), ''), '~',
                ISNULL(TRIM(src.zip), ''), '~',
                ISNULL(TRIM(src.city), ''), '~',
                ISNULL(TRIM(src.state), ''), '~',
                ISNULL(CAST(src.sqft AS VARCHAR), ''), '~',
                ISNULL(TRIM(src.contingency_descr), ''), '~',
                ISNULL(CAST(src.contingency_expiry AS VARCHAR), ''), '~',
                ISNULL(TRIM(src.buyer_name), ''), '~',
                ISNULL(TRIM(src.buyer_email), ''), '~',
                ISNULL(TRIM(src.buyer_cell_phone), ''), '~',
                ISNULL(TRIM(src.buyer_home_phone), ''), '~',
                ISNULL(TRIM(src.buyer_work_phone), ''), '~',
                ISNULL(TRIM(src.cobuyer_names), ''), '~',
                ISNULL(TRIM(src.sales_agent), ''), '~',
                ISNULL(TRIM(src.sales_agent_email), ''), '~',
                ISNULL(TRIM(src.sales_agent_cell_phone), ''), '~',
                ISNULL(TRIM(src.sales_agent_home_phone), ''), '~',
                ISNULL(TRIM(src.sales_agent_work_phone), ''), '~',
                ISNULL(TRIM(src.realtor_name), ''), '~',
                ISNULL(TRIM(src.realtor_email), ''), '~',
                ISNULL(TRIM(src.realtor_cell_phone), ''), '~',
                ISNULL(TRIM(src.realtor_home_phone), ''), '~',
                ISNULL(TRIM(src.realtor_work_phone), ''), '~',
                ISNULL(TRIM(src.agency_name), ''), '~',
                ISNULL(TRIM(src.lender), ''), '~',
                ISNULL(CAST(src.lender_preferred AS VARCHAR), ''), '~',
                ISNULL(TRIM(src.lender_contact), ''), '~',
                ISNULL(TRIM(src.loan_officer), ''), '~',
                ISNULL(TRIM(src.loan_officer_email), ''), '~',
                ISNULL(TRIM(src.loan_officer_phone), ''), '~',
                ISNULL(TRIM(src.loan_type), ''), '~',
                ISNULL(TRIM(src.title_company), ''), '~',
                ISNULL(CAST(src.total_deposits_due AS VARCHAR), ''), '~',
                ISNULL(CAST(src.deposits_paid AS VARCHAR), ''), '~',
                ISNULL(CAST(src.contract_date AS VARCHAR), ''), '~',
                ISNULL(CAST(src.submit_date AS VARCHAR), ''), '~',
                ISNULL(CAST(src.approved_date AS VARCHAR), ''), '~',
                ISNULL(CAST(src.approved_timestamp AS VARCHAR), ''), '~',
                ISNULL(CAST(src.cancel_date AS VARCHAR), ''), '~',
                ISNULL(TRIM(src.cancel_code), ''), '~',
                ISNULL(TRIM(src.cancel_reason), ''), '~',
                ISNULL(CAST(src.cancel_timestamp AS VARCHAR), ''), '~',
                ISNULL(CAST(src.is_contingent AS VARCHAR), ''), '~',
                ISNULL(CAST(src.is_transfer_to AS VARCHAR), ''), '~',
                ISNULL(TRIM(src.transfer_to_id), ''), '~',
                ISNULL(CAST(src.transfer_to_date AS VARCHAR), ''), '~',
                ISNULL(CAST(src.is_transfer_from AS VARCHAR), ''), '~',
                ISNULL(TRIM(src.transfer_from_id), ''), '~',
                ISNULL(CAST(src.transfer_from_date AS VARCHAR), '')
            )
            ), 2) AS record_hash_key,
            @current_datetime AS effective_start_date,
            @current_datetime AS created_date,
            @CreatedBy AS created_by,
            @JobRunId AS created_job_run_id
        INTO #PREP_02_dim_sale    
        FROM #PREP_01_dim_sale src
        LEFT JOIN dbo.dim_sale tgt
          ON src.sale_id = tgt.sale_id AND tgt.is_active = 'Y';

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
        FROM EDW_Silver.dbo.dim_sale tgt
        LEFT JOIN SPLive.dbo.BuyerSelections src
        ON tgt.sale_id = src.SelectionID
        WHERE src.SelectionID IS NULL AND tgt.is_active = 'Y';

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
        FROM dbo.dim_sale tgt
        JOIN #PREP_02_dim_sale src
          ON tgt.sale_id = src.sale_id
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

        INSERT INTO dbo.dim_sale (
            sale_guid, sale_id,project_id,lot_id,lot_number,sales_status,sale_type,
            street,street2,suite,zip,city,state,sqft,contingency_descr,contingency_expiry,
            buyer_name,buyer_email,buyer_cell_phone,buyer_home_phone,buyer_work_phone,
            cobuyer_names,sales_agent,sales_agent_email,sales_agent_cell_phone,sales_agent_home_phone,
            sales_agent_work_phone,realtor_name,realtor_email,realtor_cell_phone,realtor_home_phone,
            realtor_work_phone,agency_name,lender,lender_preferred,lender_contact,loan_officer,
            loan_officer_email,loan_officer_phone,loan_type,title_company,total_deposits_due,
            deposits_paid,contract_date,submit_date,approved_date,approved_timestamp,
            cancel_date,cancel_code,cancel_reason,cancel_timestamp,is_contingent,is_transfer_to,
            transfer_to_id,transfer_to_date,is_transfer_from,transfer_from_id,transfer_from_date, lastmoddatetime,
            effective_start_date, effective_end_date, is_active, is_deleted,
            created_date, created_by, created_job_run_id, record_hash_key
        )
        SELECT
            CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))), src.sale_id,src.project_id,src.lot_id,src.lot_number,src.sales_status,src.sale_type,
            src.street,src.street2,src.suite,src.zip,src.city,src.state,src.sqft,src.contingency_descr,src.contingency_expiry,
            src.buyer_name,src.buyer_email,src.buyer_cell_phone,src.buyer_home_phone,src.buyer_work_phone,
            src.cobuyer_names,src.sales_agent,src.sales_agent_email,src.sales_agent_cell_phone,
            src.sales_agent_home_phone,src.sales_agent_work_phone,src.realtor_name,src.realtor_email,src.realtor_cell_phone,
            src.realtor_home_phone,src.realtor_work_phone,src.agency_name,src.lender,
            src.lender_preferred,src.loan_officer,src.loan_officer_email,src.loan_officer_phone,
            src.lender_contact,src.loan_type,src.title_company,src.total_deposits_due,
            src.deposits_paid,src.contract_date,src.submit_date,src.approved_date,src.approved_timestamp,
            src.cancel_date,src.cancel_code,src.cancel_reason,src.cancel_timestamp,src.is_contingent,src.is_transfer_to,
            src.transfer_to_id,src.transfer_to_date,src.is_transfer_from,src.transfer_from_id,src.transfer_from_date,src.lastmoddatetime,
            src.effective_start_date, @end_date, 'Y', 'N',
            src.created_date, src.created_by, src.created_job_run_id, src.record_hash_key
        FROM #PREP_02_dim_sale src
        LEFT JOIN dbo.dim_sale tgt
          ON src.sale_id = tgt.sale_id AND tgt.is_active = 'Y'
        WHERE tgt.sale_id IS NULL OR tgt.record_hash_key <> src.record_hash_key;

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

        SELECT @total_record_count = count(sale_guid) FROM EDW_Silver.dbo.dim_sale WHERE is_active = 'Y';

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
