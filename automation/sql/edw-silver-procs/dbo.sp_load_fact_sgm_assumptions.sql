CREATE   PROCEDURE dbo.sp_load_fact_sgm_assumptions
    @CreatedBy VARCHAR(100) = 'GB_user',
    @JobRunId VARCHAR(100),
    @LoadType VARCHAR(20) = '',
	@AuditId VARCHAR(100) = '',
    @OrchestratorAuditId VARCHAR(100) = ''
AS
BEGIN
    BEGIN TRY
        DECLARE @current_datetime DATETIME2(3) = GETDATE();
		DECLARE @MaxDateTime VARCHAR(100);
		DECLARE @pipeline_audit_id VARCHAR(100) = @AuditId;
        DECLARE @Category VARCHAR(20);
        DECLARE @CategoryIndex INT = 1;

		IF @AuditId = ''
        BEGIN
            SELECT @AuditId = CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))) ;
        END;

		-- TRUNCATE logic - happens only once for FULL load
        IF @LoadType = 'FULL'
        BEGIN
            TRUNCATE TABLE EDW_Silver.dbo.fact_sgm_assumptions;
            PRINT 'Load type is FULL. EDW_Silver.dbo.fact_sgm_assumptions table truncated.'
        END
        ELSE IF @LoadType = ''
        BEGIN
            SELECT @MaxDateTime = ISNULL(CONVERT(VARCHAR(15), MAX(lastmoddatetime)),'Table is empty') FROM EDW_Silver.dbo.fact_sgm_assumptions WHERE category = 'Revenue';
            SELECT @LoadType = CASE WHEN @MaxDateTime = 'Table is empty' THEN 'FULL' ELSE 'INCREMENTAL' END;
        END;

		-- -- Audit Variables
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
		DECLARE @step_name VARCHAR(100) = '';

		-- Start SP Run Audit --
        --*************************--
        EXEC control.sp_audit_start
            @audit_id = @audit_id,
            @orchestrator_audit_id = @orchestrator_audit_id,
            @pipeline_audit_id = @pipeline_audit_id,
            @audit_type = 'SP',
            @pipeline_run_id = @JobRunId,
            @procedure_name = 'sp_load_fact_sgm_assumptions',
            @load_type = @LoadType,
            @max_date_time = @MaxDateTime,
            @created_by = @CreatedBy,
            @total_steps = @total_steps,
            @return_id = @sp_audit_id OUTPUT;
        --*************************--
        
        -- Create temporary table instead of table variable
        CREATE TABLE #CategoryList (
            CategoryIndex INT,
            Category VARCHAR(20)
        );
        
        -- Insert all categories with manual index values
        INSERT INTO #CategoryList (CategoryIndex, Category) 
        VALUES 
            (1, 'Revenue'), 
            (2, 'Gross Cost'), 
            (3, 'Direct Cost'), 
            (4, 'Distribution Cost');

        -- Loop through categories using WHILE loop
        WHILE @CategoryIndex <= 4  -- Hard-coded since we know we have 4 categories
        BEGIN
            -- Get current category from temporary table (changed from @CategoryList to #CategoryList)
            SELECT @Category = Category 
            FROM #CategoryList 
            WHERE CategoryIndex = @CategoryIndex;
            
            PRINT 'Processing Category: ' + @Category;

			SET @total_steps = 5;
			SET @current_step = 1;
			
            --------------------------
            -- STEP 1: Load PREP_01 --
            --------------------------

			-- Start Step1 Run Audit --
			--*************************--
			-- Start Step 1 audit
			SET @current_step = 1;
			SET @step_name = 'Load PREP_01 - ' + @Category
			EXEC control.sp_audit_start
				@audit_id = @audit_id,
				@audit_type = 'STEP',
				@step_number = @current_step,
				@step_name = @step_name,
				@step_description = 'Extract and prepare data from source tables',
				@return_id = @step_audit_id OUTPUT;
			--*************************--
            
			PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Loading PREP_00 & PREP_01';
			IF OBJECT_ID('tempdb..#PREP_00_fact_sgm_assumptions') IS NOT NULL DROP TABLE #PREP_00_fact_sgm_assumptions;
			IF OBJECT_ID('tempdb..#PREP_01_fact_sgm_assumptions') IS NOT NULL DROP TABLE #PREP_01_fact_sgm_assumptions;
			
			WITH TempLots_ExactMatch AS (
				SELECT 
					L.lot_id,
					A.gbp_sgmassumptions_id,
					A.gbp_major,
					A.gbp_minor,
					dsm.sgm_type, --add sgm_type
					(
						SELECT MAX(v.dt)
						FROM ( VALUES
							(L.lastmoddatetime),
							(ISNULL (FORMAT(A.modifiedon,'yyyyMMdd.HHmmss'), 19500101.000000)),
							(ISNULL (dsm.lastmoddatetime, 19500101.000000))
						) AS v (dt)
					) AS lastmoddatetime
				FROM 
					[EDW_Silver].[dbo].[dim_lot] L
					INNER JOIN [EDW_Silver].[dbo].[dim_project] P 
						ON P.project_id = L.project_id AND P.is_active = 'Y'
					INNER JOIN [dataverse_gbpdev].[dbo].[gbp_sgmassumptions] A 
						ON A.gbp_ounit = P.reporting_operating_unit_code
						AND A.gbp_project = P.project_code
						AND A.gbp_lot = L.lot_number
					INNER JOIN EDW_Silver.dbo.dim_sgm_map dsm
						ON dsm.major_code = A.gbp_major
						AND dsm.minor_code = A.gbp_minor
						AND dsm.is_active = 'Y'
				WHERE 
					L.is_active = 'Y'
					AND (L.is_backlog = 1 OR L.is_spec = 1 OR L.is_model = 1 OR L.close_date >= DATEADD(DAY,-60,GETDATE()))
					AND L.exclude_from_reporting = 0
					AND (dsm.category = @Category OR dsm.sub_category = @Category)
					AND (A.IsDelete = 0 OR A.IsDelete IS NULL)
			),

			-- CTE: Wildcard lot only ('*')
			TempLots_WildcardLot AS (
				SELECT 
					L.lot_id,
					A.gbp_sgmassumptions_id,
					A.gbp_major,
					A.gbp_minor,
					dsm.sgm_type,
					(
						SELECT MAX(v.dt)
						FROM ( VALUES
							(L.lastmoddatetime),
							(ISNULL (FORMAT(A.modifiedon,'yyyyMMdd.HHmmss'), 19500101.000000)),
							(ISNULL (dsm.lastmoddatetime, 19500101.000000))
						) AS v (dt)
					) AS lastmoddatetime
				FROM 
					[EDW_Silver].[dbo].[dim_lot] L
					INNER JOIN [EDW_Silver].[dbo].[dim_project] P 
						ON P.project_id = L.project_id AND P.is_active = 'Y'
					INNER JOIN [dataverse_gbpdev].[dbo].[gbp_sgmassumptions] A 
						ON A.gbp_ounit = P.reporting_operating_unit_code
						AND A.gbp_project = P.project_code
						AND A.gbp_lot = '*'
					LEFT JOIN TempLots_ExactMatch T 
						ON T.lot_id = L.lot_id
						AND T.gbp_major = A.gbp_major
						AND T.gbp_minor = A.gbp_minor
						--AND T.gbp_sgmassumptions_id = A.gbp_sgmassumptions_id
					INNER JOIN EDW_Silver.dbo.dim_sgm_map dsm
						ON dsm.major_code = A.gbp_major
						AND dsm.minor_code = A.gbp_minor
						AND dsm.is_active = 'Y'
				WHERE 
					L.is_active = 'Y'
					AND (L.is_backlog = 1 OR L.is_spec = 1 OR L.is_model = 1 OR L.close_date > DATEADD(DAY,-60,GETDATE()))
					AND L.exclude_from_reporting = 0
					AND (dsm.category = @Category OR dsm.sub_category = @Category)
					AND T.lot_id IS NULL
					AND (A.IsDelete = 0 OR A.IsDelete IS NULL)

				UNION ALL

				SELECT * FROM TempLots_ExactMatch
			),

			-- CTE: Wildcard project and lot ('*','*')
			TempLots_WildcardProject AS (
				SELECT 
					L.lot_id,
					A.gbp_sgmassumptions_id,
					A.gbp_major,
					A.gbp_minor,
					dsm.sgm_type,
					(
						SELECT MAX(v.dt)
						FROM ( VALUES
							(L.lastmoddatetime),
							(ISNULL (FORMAT(A.modifiedon,'yyyyMMdd.HHmmss'), 19500101.000000)),
							(ISNULL (dsm.lastmoddatetime, 19500101.000000))
						) AS v (dt)
					) AS lastmoddatetime
				FROM 
					[EDW_Silver].[dbo].[dim_lot] L
					INNER JOIN [EDW_Silver].[dbo].[dim_project] P 
						ON P.project_id = L.project_id AND P.is_active = 'Y'
					INNER JOIN [dataverse_gbpdev].[dbo].[gbp_sgmassumptions] A 
						ON A.gbp_ounit = P.reporting_operating_unit_code
						AND A.gbp_project = '*'
						AND A.gbp_lot = '*'
					LEFT JOIN TempLots_WildcardLot T ON
						T.lot_id = L.lot_id  
						AND T.gbp_major = A.gbp_major
						AND T.gbp_minor = A.gbp_minor
						--AND T.gbp_sgmassumptions_id = A.gbp_sgmassumptions_id
					INNER JOIN EDW_Silver.dbo.dim_sgm_map dsm
						ON dsm.major_code = A.gbp_major
						AND dsm.minor_code = A.gbp_minor
						AND dsm.is_active = 'Y'
				WHERE 
					L.[is_active] = 'Y'
					AND (is_backlog = 1 or L.is_spec = 1 or is_model = 1 OR L.close_date > DATEADD(day,-60,GETDATE()))
					AND L.exclude_from_reporting = 0
					AND (dsm.category = @Category OR dsm.sub_category = @Category)
					AND T.lot_id IS NULL
					AND (A.IsDelete = 0 OR A.IsDelete IS NULL)

				UNION ALL

				SELECT * FROM TempLots_WildcardLot
			),

			-- CTE: Financial matches with specific major/minor
			LFGrouping_ExactMajor AS (
				SELECT 
					L.lot_id,
					L.gbp_sgmassumptions_id,
					L.sgm_type,
					L.gbp_major AS major_code,
					L.gbp_minor AS minor_code,
					LF.anchor_estimate,
					LF.latest_est_amount,
					LF.gl_amount,
					(
						SELECT MAX(v.dt)
						FROM ( VALUES
							(ISNULL(L.lastmoddatetime, 19500101.000000)),
							(ISNULL(LF.lastmoddatetime, 19500101.000000))
						) AS v (dt)
					) AS lastmoddatetime
				FROM TempLots_WildcardProject L 
					LEFT JOIN [EDW_Silver].[dbo].[fact_lot_financials] LF --lastmoddatetinme
						ON LF.lot_id = L.lot_id
						AND LF.major_code = L.gbp_major
						AND LF.minor_code = L.gbp_minor
						AND LF.sgm_type = L.sgm_type
				WHERE L.gbp_major <> '*'
			),

			-- CTE: Aggregated minor match with wildcard major ('*')
			LFGrouping_WildcardMajor AS (
				SELECT 
					L.lot_id,
					L.gbp_sgmassumptions_id,
					L.sgm_type,
					L.gbp_major AS major_code,
					L.gbp_minor AS minor_code,
					SUM(LF.anchor_estimate) AS anchor_estimate,
					SUM(LF.latest_est_amount) AS latest_est_amount,
					SUM(LF.gl_amount) AS gl_amount,
					MAX(
						CASE 
							WHEN ISNULL (L.lastmoddatetime, 19500101.000000) > 
								ISNULL(LF.lastmoddatetime, 19500101.000000)
							THEN ISNULL (L.lastmoddatetime, 19500101.000000)
							ELSE ISNULL(LF.lastmoddatetime, 19500101.000000)
						END
					) AS lastmoddatetime
				FROM TempLots_WildcardProject L 
					LEFT JOIN [EDW_Silver].[dbo].[fact_lot_financials] LF --lastmoddatetinme
						ON LF.lot_id = L.lot_id
						AND LF.minor_code = L.gbp_minor
					LEFT JOIN LFGrouping_ExactMajor G 
						ON G.lot_id = L.lot_id
						AND G.gbp_sgmassumptions_id = L.gbp_sgmassumptions_id
						AND G.major_code = LF.major_code
						AND G.minor_code = LF.minor_code
						AND G.sgm_type = L.sgm_type
				WHERE L.gbp_major = '*'
					AND G.lot_id IS NULL
				GROUP BY 
					L.lot_id,
					L.gbp_sgmassumptions_id,
					L.sgm_type,
					L.gbp_major,
					L.gbp_minor
			),

			-- Final SELECT (mimics contents of #LFGrouping)
			LFGrouping AS (
				SELECT *,@Category AS category FROM LFGrouping_ExactMajor
				UNION ALL
				SELECT *,@Category AS category FROM LFGrouping_WildcardMajor
			),

			SGMAssumptions AS (
				SELECT 
					G.lot_id AS lot_id,
					G.gbp_sgmassumptions_id AS assumption_id,
					G.sgm_type,
					G.major_code AS major_code,
					G.minor_code AS minor_code,
					G.anchor_estimate AS anchor_estimate,
					G.latest_est_amount AS latest_est_amount,
					G.gl_amount AS gl_amount,
					AV1.gbp_sgmassumptionvalue_id AS assumption_value_id,
					AV1.gbp_effectivedate AS effective_date,
					AV1.gbp_sgmtrigger1name trigger1_name,
					AV1.gbp_sgmtrigger2name AS trigger2_name,
					AV1.[gbp_sgmcalculationbasisname] AS calculation_basis,
					CAST(
						CASE
							WHEN AV1.[gbp_valuetype] = 1 THEN AV1.[gbp_value]
							ELSE
								CASE 
									WHEN G.category = 'Revenue' THEN AV1.[gbp_value]
									ELSE AV1.[gbp_value] * 
										ISNULL(
											(
												SELECT
													CASE AV1.gbp_sgmcalculationbasisname
														WHEN NULL THEN 1
														WHEN 'Base Revenue'
															THEN SUM(CASE WHEN M.sgm_type = '3020' THEN CASE WHEN A.use_assumption = 1 THEN A.calculation_amount ELSE A.latest_est_amount END ELSE 0 END)
														WHEN 'Sales Opt Revenue'
															THEN SUM(CASE WHEN M.sgm_type = '3021' THEN CASE WHEN A.use_assumption = 1 THEN A.calculation_amount ELSE A.latest_est_amount END ELSE 0 END)
														WHEN 'Design Opt Revenue'
															THEN SUM(CASE WHEN M.sgm_type = '3022' THEN CASE WHEN A.use_assumption = 1 THEN A.calculation_amount ELSE A.latest_est_amount END ELSE 0 END)
														WHEN 'Custom Opt Revenue'
															THEN SUM(CASE WHEN M.sgm_type = '3023' THEN CASE WHEN A.use_assumption = 1 THEN A.calculation_amount ELSE A.latest_est_amount END ELSE 0 END)
														WHEN 'Net Revenue'
															THEN 
																SUM(CASE WHEN M.sub_category = 'Gross Revenue' THEN CASE WHEN A.use_assumption = 1 THEN A.calculation_amount ELSE A.latest_est_amount END ELSE 0 END)
																- SUM(CASE WHEN M.sub_category = 'Net Revenue' THEN CASE WHEN A.use_assumption = 1 THEN A.calculation_amount ELSE A.latest_est_amount END ELSE 0 END)
														WHEN 'Net Revenue less Lot Revenue'
															THEN 
																SUM(CASE WHEN M.sub_category = 'Gross Revenue' THEN CASE WHEN A.use_assumption = 1 THEN A.calculation_amount ELSE A.latest_est_amount END ELSE 0 END)
																- SUM(CASE WHEN M.sub_category = 'Net Revenue' THEN CASE WHEN A.use_assumption = 1 THEN A.calculation_amount ELSE A.latest_est_amount END ELSE 0 END)
																- SUM(CASE WHEN M.sgm_type = '3030' THEN CASE WHEN A.use_assumption = 1 THEN A.calculation_amount ELSE A.latest_est_amount END ELSE 0 END)
														WHEN 'Gross Constrution Costs'
															THEN SUM(CASE WHEN M.sub_category = 'Gross Cost' THEN CASE WHEN A.use_assumption = 1 THEN A.calculation_amount ELSE A.latest_est_amount END ELSE 0 END)
														WHEN 'Direct Construction Costs'
															THEN SUM(CASE WHEN M.sub_category IN ('Gross Cost','Direct Cost') THEN CASE WHEN A.use_assumption = 1 THEN A.calculation_amount ELSE A.latest_est_amount END ELSE 0 END)
														WHEN 'Contribution Construction Costs'
															THEN SUM(CASE WHEN M.sub_category IN ('Gross Cost','Direct Cost','Contribution Cost') THEN CASE WHEN A.use_assumption = 1 THEN A.calculation_amount ELSE A.latest_est_amount END ELSE 0 END)
													END
												FROM EDW_Silver.dbo.fact_sgm_assumptions A
												INNER JOIN EDW_Silver.dbo.dim_sgm_map M
													ON M.major_code = A.major_code AND M.minor_code = A.minor_code AND M.is_active = 'Y'
												WHERE A.lot_id = G.lot_id
											), 0)
								END
						END
					AS DECIMAL(15,2)) AS calculation_amount,
					G.category,
					G.lastmoddatetime,
					AV1.gbp_effectivedate
				FROM LFGrouping G
				/*
				INNER JOIN (
					SELECT 
						gbp_sgmassumptionname,
						gbp_sgmassumptionvalue_id,
						gbp_effectivedate,
						ROW_NUMBER() OVER (
							PARTITION BY gbp_sgmassumptionname 
							ORDER BY gbp_effectivedate DESC
						) as rn
					FROM [dataverse_gbpdev].[dbo].[gbp_sgmassumptionvalues] V
					WHERE gbp_effectivedate <= GETDATE()
				) AV ON G.[gbp_sgmassumptions_id] = AV.[gbp_sgmassumptionname] 
					AND AV.rn = 1
					*/
				INNER JOIN [dataverse_gbpdev].[dbo].[gbp_sgmassumptionvalues] AV1
				ON AV1.gbp_sgmassumptionname = G.[gbp_sgmassumptions_id]
				--AND AV.rn = 1
			)
			SELECT 
				CONCAT(s.lot_id,'_',s.major_code,'_',s.minor_code,'_',CAST(s.effective_date AS VARCHAR(20))) AS sgm_assumptions_id,
				s.lot_id,
				s.assumption_id,
				s.sgm_type, 
				s.major_code,
				s.minor_code,
				ISNULL(s.anchor_estimate,0) AS anchor_estimate,
				ISNULL(s.latest_est_amount,0) AS latest_est_amount,
				ISNULL(s.gl_amount,0) AS gl_amount,
				s.assumption_value_id,
				s.effective_date,
				s.trigger1_name,
				-- Inline logic for trigger1_met
				CASE
					-- Milestone-based triggers
					WHEN s.trigger1_name IN (
						'001JSTRT - Job Start', '002FNDTN - Foundation Complete', '003FRAME - Frame Complete', 
						'004MCRGH - Mechanical Rough Complete', '005DRYWL - Drywall Complete',
						'006INTTM - Interior Trim Complete', '007MCTRM - Mechanical Trim Complete', 
						'008FLOOR - Flooring Complete', '009QIC - Job Complete'
					) THEN 
						CASE 
							WHEN EXISTS (
								SELECT 1 
								FROM EDW_Silver.dbo.dim_job_task jt 
								LEFT JOIN EDW_Silver.dbo.dim_job j ON jt.job_id = j.job_id
								WHERE j.lot_id = s.lot_id
									AND jt.task_code = LEFT(s.trigger1_name, CHARINDEX(' - ', s.trigger1_name + ' - ') - 1)
									AND jt.corp_milestone_num = 1
									AND jt.actual_end_date IS NULL
							) THEN 1 
							ELSE 0 
						END
					-- Financial-based triggers
					WHEN s.trigger1_name = 'Actuals Greater' THEN
						CASE 
							WHEN EXISTS (
								SELECT 1 
								FROM EDW_Silver.dbo.fact_lot_financials 
								WHERE lot_id = s.lot_id
									AND major_code = s.major_code
									AND minor_code = s.minor_code
								GROUP BY lot_id, major_code, minor_code 
								HAVING SUM(gl_amount) > s.calculation_amount
							) THEN 1 
							ELSE 0 
						END
					WHEN s.trigger1_name = 'Actuals Present' THEN
						CASE 
							WHEN NOT EXISTS (
								SELECT 1 
								FROM EDW_Silver.dbo.fact_lot_financials 
								WHERE lot_id = s.lot_id
									AND major_code = s.major_code
									AND minor_code = s.minor_code
								GROUP BY lot_id, major_code, minor_code 
								HAVING SUM(gl_amount) IS NULL
							) THEN 1 
							ELSE 0 
						END
					-- Sale-based triggers
					WHEN s.trigger1_name = 'Realtor Present' THEN
						CASE 
							WHEN EXISTS (
								SELECT 1 FROM EDW_Silver.dbo.dim_sale 
								WHERE lot_id = s.lot_id 
									AND sales_status NOT IN ('Transfer', 'Cancelled')
									AND realtor_name IS NOT NULL
							) THEN 1 
							ELSE 0 
						END
					WHEN s.trigger1_name = 'Sale Date' THEN
						CASE 
							WHEN EXISTS (
								SELECT 1 FROM EDW_Silver.dbo.dim_sale 
								WHERE lot_id = s.lot_id 
									AND sales_status NOT IN ('Transfer', 'Cancelled')
									AND approved_date IS NULL
							) THEN 1 
							ELSE 0 
						END
					-- Lot-based triggers
					WHEN s.trigger1_name = 'Closing Date' THEN
						CASE 
							WHEN EXISTS (
								SELECT 1 FROM EDW_Silver.dbo.dim_lot 
								WHERE lot_id = s.lot_id 
									AND close_date IS NULL
							) THEN 1 
							ELSE 0 
						END
					WHEN s.trigger1_name = 'Spec/Model' THEN
						CASE 
							WHEN EXISTS (
								SELECT 1 FROM EDW_Silver.dbo.dim_lot 
								WHERE lot_id = s.lot_id 
									AND lot_status IN ('Spec', 'Model')
							) THEN 1 
							ELSE 0 
						END
					ELSE 0
				END AS trigger1_met,
				s.trigger2_name,
				-- Inline logic for trigger2_met
				CASE
					-- Milestone-based triggers
					WHEN s.trigger2_name IN (
						'001JSTRT - Job Start', '002FNDTN - Foundation Complete', '003FRAME - Frame Complete', 
						'004MCRGH - Mechanical Rough Complete', '005DRYWL - Drywall Complete',
						'006INTTM - Interior Trim Complete', '007MCTRM - Mechanical Trim Complete', 
						'008FLOOR - Flooring Complete', '009QIC - Job Complete'
					) THEN 
						CASE 
							WHEN EXISTS (
								SELECT 1 
								FROM EDW_Silver.dbo.dim_job_task jt 
								LEFT JOIN EDW_Silver.dbo.dim_job j ON jt.job_id = j.job_id
								WHERE j.lot_id = s.lot_id
									AND jt.task_code = LEFT(s.trigger2_name, CHARINDEX(' - ', s.trigger2_name + ' - ') - 1)
									AND jt.corp_milestone_num = 1
									AND jt.actual_end_date IS NULL
							) THEN 1 
							ELSE 0 
						END
					-- Financial-based triggers
					WHEN s.trigger2_name = 'Actuals Greater' THEN
						CASE 
							WHEN EXISTS (
								SELECT 1 
								FROM EDW_Silver.dbo.fact_lot_financials 
								WHERE lot_id = s.lot_id
									AND major_code = s.major_code
									AND minor_code = s.minor_code
								GROUP BY lot_id, major_code, minor_code 
								HAVING SUM(gl_amount) > s.calculation_amount
							) THEN 1 
							ELSE 0 
						END
					WHEN s.trigger2_name = 'Actuals Present' THEN
						CASE 
							WHEN NOT EXISTS (
								SELECT 1 
								FROM EDW_Silver.dbo.fact_lot_financials 
								WHERE lot_id = s.lot_id
									AND major_code = s.major_code
									AND minor_code = s.minor_code
								GROUP BY lot_id, major_code, minor_code 
								HAVING SUM(gl_amount) IS NULL
							) THEN 1 
							ELSE 0 
						END
					-- Sale-based triggers
					WHEN s.trigger2_name = 'Realtor Present' THEN
						CASE 
							WHEN EXISTS (
								SELECT 1 FROM EDW_Silver.dbo.dim_sale 
								WHERE lot_id = s.lot_id 
									AND sales_status NOT IN ('Transfer', 'Cancelled')
									AND realtor_name IS NOT NULL
							) THEN 1 
							ELSE 0 
						END
					WHEN s.trigger2_name = 'Sale Date' THEN
						CASE 
							WHEN EXISTS (
								SELECT 1 FROM EDW_Silver.dbo.dim_sale 
								WHERE lot_id = s.lot_id 
									AND sales_status NOT IN ('Transfer', 'Cancelled')
									AND approved_date IS NULL
							) THEN 1 
							ELSE 0 
						END
					-- Lot-based triggers
					WHEN s.trigger2_name = 'Closing Date' THEN
						CASE 
							WHEN EXISTS (
								SELECT 1 FROM EDW_Silver.dbo.dim_lot 
								WHERE lot_id = s.lot_id 
									AND close_date IS NULL
							) THEN 1 
							ELSE 0 
						END
					WHEN s.trigger2_name = 'Spec/Model' THEN
						CASE 
							WHEN EXISTS (
								SELECT 1 FROM EDW_Silver.dbo.dim_lot 
								WHERE lot_id = s.lot_id 
									AND lot_status IN ('Spec', 'Model')
							) THEN 1 
							ELSE 0 
						END
					ELSE 0
				END AS trigger2_met,
				s.calculation_basis,
				s.calculation_amount,
				-- Inline logic for use_assumption
				use_assumption = NULL,
				s.category,
				s.lastmoddatetime,
				gbp_effectivedate AS gbp_effective_date
			INTO #PREP_00_fact_sgm_assumptions
			FROM SGMAssumptions s;

			UPDATE #PREP_00_fact_sgm_assumptions
			SET use_assumption = 
				CASE 
					WHEN sgm_type NOT IN ('3591') THEN 
						CASE 
							WHEN trigger1_met = 1 AND (trigger2_met = 1 OR trigger2_met IS NULL) THEN 1 
							ELSE 0 
						END
					WHEN trigger1_met = 1 OR trigger2_met = 1 THEN 1 
					ELSE 0 
				END;


			SELECT * 
			INTO #PREP_01_fact_sgm_assumptions
			FROM #PREP_00_fact_sgm_assumptions
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
			SET @step_name = 'Load PREP_02 - ' + @Category
			EXEC control.sp_audit_start
				@audit_id = @audit_id,
				@audit_type = 'STEP',
				@step_number = @current_step,
				@step_name = @step_name,
				@step_description = 'Generate hash keys and prepare final dataset',
				@return_id = @step_audit_id OUTPUT;
			--*************************--

            PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Loading PREP_02';
			IF OBJECT_ID('tempdb..#PREP_02_fact_sgm_assumptions') IS NOT NULL DROP TABLE #PREP_02_fact_sgm_assumptions;
			SELECT 
				src.*,
				CONVERT(
					VARCHAR(64), 
					HASHBYTES('SHA2_256',
						CONCAT(
							ISNULL(TRIM(src.lot_id), ''), '~',
							ISNULL(TRIM(src.assumption_id), ''), '~',
							ISNULL(TRIM(src.sgm_type), ''), '~',
							ISNULL(TRIM(src.major_code), ''), '~',
							ISNULL(TRIM(src.minor_code), ''), '~',
							ISNULL(CONVERT(VARCHAR, src.anchor_estimate), ''), '~',
							ISNULL(CONVERT(VARCHAR, src.latest_est_amount), ''), '~',
							ISNULL(CONVERT(VARCHAR, src.gl_amount), ''), '~',
							ISNULL(TRIM(src.assumption_value_id), ''), '~',
							ISNULL(CONVERT(VARCHAR, src.effective_date), ''), '~',
							ISNULL(TRIM(src.trigger1_name), ''), '~',
							ISNULL(CONVERT(VARCHAR, src.trigger1_met), ''), '~',
							ISNULL(TRIM(src.trigger2_name), ''), '~',
							ISNULL(CONVERT(VARCHAR, src.trigger2_met), ''), '~',
							ISNULL(TRIM(src.calculation_basis), ''), '~',
							ISNULL(CONVERT(VARCHAR, src.calculation_amount), ''), '~',
							ISNULL(CONVERT(VARCHAR, src.use_assumption), ''), '~',
							ISNULL(CONVERT(VARCHAR, src.gbp_effective_date), ''), '~',
							ISNULL(TRIM(src.category), '')
						) 
					), 
					2
				) as record_hash_key,
				@current_datetime AS created_date,
				@CreatedBy AS created_by,
				@JobRunId AS created_job_run_id
			INTO #PREP_02_fact_sgm_assumptions 
			FROM #PREP_01_fact_sgm_assumptions as src;

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
            -- STEP 3: Delete Hard-Deleted records --
            -------------------------------------------------

			-- Start Step3 Run Audit --
			--*************************--
			SET @step_name = 'Delete hard-deleted records - ' + @Category
			EXEC control.sp_audit_start
				@audit_id = @audit_id,
				@audit_type = 'STEP',
				@step_number = @current_step,
				@step_name = @step_name,
				@step_description = 'Delete hard-deleted records',
				@return_id = @step_audit_id OUTPUT;
			--*************************--

            PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Delete Hard-Deleted Records';

            DELETE tgt
			FROM EDW_Silver.dbo.fact_sgm_assumptions tgt
			JOIN #PREP_00_fact_sgm_assumptions src
				ON src.sgm_assumptions_id = tgt.sgm_assumptions_id
			WHERE src.sgm_assumptions_id IS NULL;

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

            -------------------------------------------------
            -- STEP 4: Delete Updated records --
            -------------------------------------------------

			-- Start Step4 Run Audit --
			--*************************--
			SET @step_name = 'Delete updated records - ' + @Category
			EXEC control.sp_audit_start
				@audit_id = @audit_id,
				@audit_type = 'STEP',
				@step_number = @current_step,
				@step_name = @step_name,
				@step_description = 'Delete updated records',
				@return_id = @step_audit_id OUTPUT;
			--*************************--

			PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Delete Updated Records';

            DELETE tgt
            FROM EDW_Silver.dbo.fact_sgm_assumptions tgt
            JOIN #PREP_02_fact_sgm_assumptions src
                ON src.sgm_assumptions_id = tgt.sgm_assumptions_id
            WHERE tgt.record_hash_key <> src.record_hash_key
                AND tgt.category = @Category;

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
			SET @step_name = 'Insert New/Changed Records - ' + @Category
			EXEC control.sp_audit_start
				@audit_id = @audit_id,
				@audit_type = 'STEP',
				@step_number = @current_step,
				@step_name = @step_name,
				@step_description = 'Insert new and changed records into target table',
				@return_id = @step_audit_id OUTPUT;
			--*************************--

            PRINT 'Step ' + CAST(@current_step AS VARCHAR) + ': Insert New/Changed Records';

            INSERT INTO EDW_Silver.dbo.fact_sgm_assumptions (
                sgm_assumptions_guid, sgm_assumptions_id, lot_id, assumption_id, sgm_type, major_code, minor_code, anchor_estimate, 
                latest_est_amount, gl_amount, assumption_value_id, effective_date, trigger1_name, trigger1_met,
                trigger2_name, trigger2_met, calculation_basis, calculation_amount, use_assumption,
                category, lastmoddatetime, created_date, record_hash_key, created_by, created_job_run_id
            )
            SELECT
				CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE()))) AS sgm_assumptions_guid,
                src.sgm_assumptions_id,
                src.lot_id,
                src.assumption_id,
                src.sgm_type,
                src.major_code,
                src.minor_code,
                src.anchor_estimate,
                src.latest_est_amount,
                src.gl_amount,
                src.assumption_value_id,
                src.effective_date,
                src.trigger1_name,
                src.trigger1_met,
                src.trigger2_name,
                src.trigger2_met,
                src.calculation_basis,
                src.calculation_amount,
                src.use_assumption,
                src.category,
                src.lastmoddatetime,
                src.created_date,
                src.record_hash_key,
                src.created_by,
                src.created_job_run_id
            FROM #PREP_02_fact_sgm_assumptions src
            LEFT JOIN EDW_Silver.dbo.fact_sgm_assumptions tgt
                ON src.sgm_assumptions_id = tgt.sgm_assumptions_id
            WHERE tgt.sgm_assumptions_id IS NULL;

			-- End Step5 Run Audit --
			--*************************--
			SET @records_affected = @@ROWCOUNT;
			SET @total_inserted += @records_affected;
			EXEC control.sp_audit_end
				@audit_type = 'STEP',
				@audit_id = @step_audit_id,
				@status = 'SUCCESS',
				@records_affected = @records_affected;
			--*************************--

            PRINT 'Category ' + @Category + ' processing completed successfully.';
            
            -- Increment to next category
            SET @CategoryIndex = @CategoryIndex + 1;
        END

        -- Clean up category list temp table
        DROP TABLE #CategoryList;

        PRINT 'All categories processed successfully.';

		SELECT @total_record_count = count(sgm_assumptions_guid) FROM EDW_Silver.dbo.fact_sgm_assumptions;

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
