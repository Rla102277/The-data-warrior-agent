



CREATE     VIEW vw_rep_lot_events AS

WITH JobStarts AS (
    --Job Start Events
	SELECT DISTINCT
	--Operating dimensions that owns event
		 'UnitCode'					= dp.reporting_operating_unit_code
		,'ProjectCode'				= dp.project_code
		,'ProjectID'				= dp.project_id
		,'LotNo'					= dl.lot_number
		,'LotKey'					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number

	--Ownership Details
		,'Operating Unit Name'		= do.operating_unit_name
		,'Project Name'				= dp.project_name
		,'Lot Address'				= dl.street + CASE WHEN dl.street2 <> '' THEN ' ' + dl.street2 ELSE '' END

	--LotEvent Key
		,'LotEventKey'				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number + '|StartEvent|NSE'

	--Event Details
		,'Event Source'				= 'BuildPro/NSE'
		,'Event Date'				= dj.start_date 
		,'Date'						= CAST(dj.start_date  AS DATE)
		,'Event Category'			= 'Starts'
		,'Event Type'				= '1-Job Started'
		,'Event Value'				= 1
		,'EventAgeDays'				= DATEDIFF(d, dj.start_date, GETDATE())
		,'Last Completed Task'		= CASE WHEN dj.current_corp_milestone = 1 THEN 1 ELSE 0 END
		,'DaysAgeBin306090'			= CASE 
										   WHEN DATEDIFF(d, dj.start_date, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, dj.start_date, GETDATE()) < 60 THEN '30-59'
										   WHEN DATEDIFF(d, dj.start_date, GETDATE()) < 90 THEN '60-89'
										   WHEN DATEDIFF(d, dj.start_date, GETDATE()) > 90 THEN '>=90'
										   ELSE ''
									  END
		,'DaysAgeBin90180'			= CASE 
										   WHEN DATEDIFF(d, dj.start_date, GETDATE()) < 90 THEN '1-90'
										   WHEN DATEDIFF(d, dj.start_date, GETDATE()) < 180 THEN '91-180'
										   WHEN DATEDIFF(d, dj.start_date, GETDATE()) >= 90 THEN '180+'
										   ELSE ''
									  END
		,'lot_id'					= dl.lot_id
		,'sale_id'					= NULL--ds.sale_id
		,'job_id'					= dj.job_id
		,'Net_Revenue'				= 0.00
		,'SQFT'						= 0.00
		,FORMAT(dj.start_date, 'yyyy-MM') AS MonthYear
		,YEAR(dj.start_date) * 100 + MONTH(dj.start_date) AS MonthYearSort
   FROM EDW_Silver.dbo.dim_lot dl
        INNER JOIN EDW_Silver.dbo.dim_project dp
            ON dp.project_id = dl.project_id
                AND dp.is_active = 'Y'
        INNER JOIN EDW_Silver.dbo.dim_operating_unit do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
            AND do.is_active = 'Y'
        INNER JOIN EDW_Silver.dbo.dim_job dj
            ON dj.lot_id = dl.lot_id
            AND dj.is_active = 'Y'
            AND dj.job_active = 1
            AND dj.start_date IS NOT NULL
    WHERE dl.exclude_from_reporting = 0
        AND dl.is_active = 'Y'
        AND (dl.lot_transfer_date IS NULL OR dl.lot_transfer_date > dj.start_date)
),

BuildProTasks AS (	
	--BuildPro Task Events
	SELECT DISTINCT
	--Operating dimensions that owns event
		 'UnitCode'					= dp.reporting_operating_unit_code
		,'ProjectCode'				= dp.project_code
		,'ProjectID'				= dp.project_id
		,'LotNo'					= dl.lot_number
		,'LotKey'					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number

	--Ownership Details
		,'Operating Unit Name'		= do.operating_unit_name
		,'Project Name'				= dp.project_name
		,'Lot Address'				= dl.street + CASE WHEN dl.street2 <> '' THEN ' ' + dl.street2 ELSE '' END

	--LotEvent Key
		,'LotEventKey'				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number + '|TaskEvent|' + djt.task_code + '|' + CAST(djt.task_id AS VARCHAR(10))
	
	--Event Details
		,'Event Source'				= 'BuildPro'
		,'Event Date'				= djt.actual_end_date
		,'Date'						= CAST(djt.actual_end_date AS DATE)
		,'Event Category'			= 'Tasks'
		,'Event Type'				= CASE WHEN djt.task_code = '00PRDTST'  THEN 'Pending Start'
										   WHEN djt.task_code = '00PPERMIT' THEN 'Permit Issued'
										   WHEN djt.task_code = '002FNDTN'  THEN '2-Foundation'
										   WHEN djt.task_code = '003FRAME'  THEN '3-Frame'
										   WHEN djt.task_code = '004MCRGH'  THEN '4-Mechanical Rough'
										   WHEN djt.task_code = '005DRYWL'  THEN '5-Drywall'
										   WHEN djt.task_code = '006INTTM'  THEN '6-Interior Trim'
										   WHEN djt.task_code = '007MCTRM'  THEN '7-Mechanical Trim'
										   WHEN djt.task_code = '008FLOOR'  THEN '8-Flooring'
										   ELSE NULL
										END
		,'Event Value'				= 1
		,'EventAgeDays'				= DATEDIFF(d, djt.actual_end_date, GETDATE())
		,'Last Completed Task'		= CASE WHEN djt.corp_milestone_num = dj.current_corp_milestone THEN 1 ELSE 0 END
		,'DaysAgeBin306090'			= CASE 
										   WHEN DATEDIFF(d, djt.actual_end_date, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, djt.actual_end_date, GETDATE()) < 60 THEN '30-59'
										   WHEN DATEDIFF(d, djt.actual_end_date, GETDATE()) < 90 THEN '60-89'
										   WHEN DATEDIFF(d, djt.actual_end_date, GETDATE()) >= 90 THEN '>=90'
										   ELSE ''
									  END
		,'DaysAgeBin90180'			= CASE 
										   WHEN DATEDIFF(d, djt.actual_end_date, GETDATE()) < 90 THEN '1-90'
										   WHEN DATEDIFF(d, djt.actual_end_date, GETDATE()) < 180 THEN '91-180'
										   WHEN DATEDIFF(d, djt.actual_end_date, GETDATE()) >= 90 THEN '180+'
										   ELSE ''
									  END
		,'lot_id'					= dl.lot_id
		,'sale_id'					= NULL--ds.sale_id
		,'job_id'					= dj.job_id
		,'Net_Revenue'				= 0.00
		,'SQFT'						= 0.00
		,FORMAT(djt.actual_end_date, 'yyyy-MM') AS MonthYear
		,YEAR(djt.actual_end_date) * 100 + MONTH(djt.actual_end_date) AS MonthYearSort
	FROM EDW_Silver.dbo.dim_lot dl
        INNER JOIN EDW_Silver.dbo.dim_project dp
            ON dp.project_id = dl.project_id
                AND dp.is_active = 'Y'
        INNER JOIN EDW_Silver.dbo.dim_operating_unit do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
            AND do.is_active = 'Y'
        LEFT JOIN EDW_Silver.dbo.dim_job dj
            ON dj.lot_id = dl.lot_id
            AND dj.is_active = 'Y'
            AND dj.job_active = 1
        INNER JOIN EDW_Silver.dbo.dim_job_task djt
            ON djt.job_id = dj.job_id
            AND djt.corp_milestone_num IS NOT NULL
            AND djt.actual_end_date IS NOT NULL
    WHERE dl.exclude_from_reporting = 0
        AND dl.is_active = 'Y'
        AND (dl.lot_transfer_date IS NULL OR dl.lot_transfer_date > djt.actual_end_date)
        AND djt.task_code NOT IN ('001JSTRT','009QIC')
),
	
    RevertToDirts AS (
    --Revert to Dirt
	SELECT DISTINCT
	--Operating dimensions that owns event
		 'UnitCode'					= dp.reporting_operating_unit_code
		,'ProjectCode'				= dp.project_code
		,'ProjectID'				= dp.project_id
		,'LotNo'					= dl.lot_number
		,'LotKey'					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number

	--Ownership Details
		,'Operating Unit Name'		= do.operating_unit_name
		,'Project Name'				= dp.project_name
		,'Lot Address'				= dl.street + CASE WHEN dl.street2 <> '' THEN ' ' + dl.street2 ELSE '' END

	--LotEvent Key
		,'LotEventKey'				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number + '|StartEvent|NSE'

	--Event Details
		,'Event Source'				= 'NSE'
		,'Event Date'				= dj.revert_to_dirt_date 
		,'Date'						= CAST(dj.revert_to_dirt_date  AS DATE)
		,'Event Category'			= 'Starts'
		,'Event Type'				= 'Revert to Dirt'
		,'Event Value'				= 1
		,'EventAgeDays'				= DATEDIFF(d, dj.revert_to_dirt_date, GETDATE())
		,'Last Completed Task'		= CASE WHEN dj.current_corp_milestone = 1 THEN 1 ELSE 0 END
		,'DaysAgeBin306090'			= CASE 
										   WHEN DATEDIFF(d, dj.revert_to_dirt_date, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, dj.revert_to_dirt_date, GETDATE()) < 60 THEN '30-59'
										   WHEN DATEDIFF(d, dj.revert_to_dirt_date, GETDATE()) < 90 THEN '60-89'
										   WHEN DATEDIFF(d, dj.revert_to_dirt_date, GETDATE()) > 90 THEN '>=90'
										   ELSE ''
									  END
		,'DaysAgeBin90180'			= CASE 
										   WHEN DATEDIFF(d, dj.revert_to_dirt_date, GETDATE()) < 90 THEN '1-90'
										   WHEN DATEDIFF(d, dj.revert_to_dirt_date, GETDATE()) < 180 THEN '91-180'
										   WHEN DATEDIFF(d, dj.revert_to_dirt_date, GETDATE()) >= 90 THEN '180+'
										   ELSE ''
									  END
		,'lot_id'					= dl.lot_id
		,'sale_id'					= NULL--ds.sale_id
		,'job_id'					= dj.job_id
		,'Net_Revenue'				= 0.00
		,'SQFT'						= 0.00
		,FORMAT(dj.revert_to_dirt_date, 'yyyy-MM') AS MonthYear
		,YEAR(dj.revert_to_dirt_date) * 100 + MONTH(dj.revert_to_dirt_date) AS MonthYearSort
   FROM EDW_Silver.dbo.dim_lot dl
        INNER JOIN EDW_Silver.dbo.dim_project dp
            ON dp.project_id = dl.project_id
                AND dp.is_active = 'Y'
        INNER JOIN EDW_Silver.dbo.dim_operating_unit do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
            AND do.is_active = 'Y'
        INNER JOIN EDW_Silver.dbo.dim_job dj
            ON dj.lot_id = dl.lot_id
            AND dj.is_active = 'Y'
            AND dj.job_active = 1
            AND dj.revert_to_dirt_date IS NOT NULL
    WHERE dl.exclude_from_reporting = 0
        AND dl.is_active = 'Y'
        AND (dl.lot_transfer_date IS NULL OR dl.lot_transfer_date > dj.revert_to_dirt_date)
),

QICEvents AS (																													 

	--NSE QIC Events
	SELECT DISTINCT
	--Operating dimensions that owns event
		 'UnitCode'					= dp.reporting_operating_unit_code
		,'ProjectCode'				= dp.project_code
		,'ProjectID'				= dp.project_id
		,'LotNo'					= dl.lot_number
		,'LotKey'					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number

	--Ownership Details
		,'Operating Unit Name'		= do.operating_unit_name
		,'Project Name'				= dp.project_name
		,'Lot Address'				= dl.street + CASE WHEN dl.street2 <> '' THEN ' ' + dl.street2 ELSE '' END

	--LotEvent Key
		,'LotEventKey'				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number + '|QIEvent|NSE'

	--Event Details
		,'Event Source'				= 'BuildPro/NSE'
		,'Event Date'				= dj.complete_date
		,'Date'						= CAST(dj.complete_date AS DATE)
		,'Event Category'			= 'Tasks'
		,'Event Type'				= '9-QI/Job'
		,'Event Value'				= 1
		,'EventAgeDays'				= DATEDIFF(d,dj.complete_date, GETDATE())
		,'Last Completed Task'		= 1
		,'DaysAgeBin306090'			= CASE 
										   WHEN DATEDIFF(d, dj.complete_date, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, dj.complete_date, GETDATE()) < 60 THEN '30-59'
										   WHEN DATEDIFF(d, dj.complete_date, GETDATE()) < 90 THEN '60-89'
										   WHEN DATEDIFF(d, dj.complete_date, GETDATE()) > 90 THEN '>=90'
										   ELSE ''
									  END
		,'DaysAgeBin90180'			= CASE 
										   WHEN DATEDIFF(d, dj.complete_date, GETDATE()) < 90 THEN '1-90'
										   WHEN DATEDIFF(d, dj.complete_date, GETDATE()) < 180 THEN '91-180'
										   WHEN DATEDIFF(d, dj.complete_date, GETDATE()) >= 90 THEN '180+'
										   ELSE ''
									  END
		,'lot_id'					= dl.lot_id
		,'sale_id'					= NULL--ds.sale_id
		,'job_id'					= dj.job_id
		,'Net_Revenue'				= 0.00
		,'SQFT'						= 0.00
		,FORMAT(dj.complete_date, 'yyyy-MM') AS MonthYear
		,YEAR(dj.complete_date) * 100 + MONTH(dj.complete_date) AS MonthYearSort
    FROM EDW_Silver.dbo.dim_lot dl
        INNER JOIN EDW_Silver.dbo.dim_project dp
            ON dp.project_id = dl.project_id
                AND dp.is_active = 'Y'
        INNER JOIN EDW_Silver.dbo.dim_operating_unit do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
            AND do.is_active = 'Y'
        INNER JOIN EDW_Silver.dbo.dim_job dj
            ON dj.lot_id = dl.lot_id
            AND dj.is_active = 'Y'
            AND dj.job_active = 1
            AND dj.complete_date IS NOT NULL
    WHERE dl.exclude_from_reporting = 0
        AND dl.is_active = 'Y'
        AND (dl.lot_transfer_date IS NULL OR dl.lot_transfer_date > dj.complete_date)

),

PendingSales As (
	--Pending Sale Events
	SELECT DISTINCT
	--Operating dimensions that owns event
		 'UnitCode'					= dp.reporting_operating_unit_code
		,'ProjectCode'				= dp.project_code
		,'ProjectID'				= dp.project_id
		,'LotNo'					= dl.lot_number
		,'LotKey'					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number

	--Ownership Details
		,'Operating Unit Name'		= do.operating_unit_name
		,'Project Name'				= dp.project_name
		,'Lot Address'				= dl.street + CASE WHEN dl.street2 <> '' THEN ' ' + dl.street2 ELSE '' END

	--LotEvent Key
		,'LotEventKey'				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number + '|' + 'SaleEvent|' + CAST(ds.sale_id AS VARCHAR(20))

	--Event Details
		,'Event Source'				= 'NSS'
		,'Event Date'				= ds.submit_date
		,'Date'						= CAST(ds.submit_date AS DATE)
		,'Event Category'			= 'Sales'
		,'Event Type'				= 'Pending Sale'
		,'Event Value'				= 1
		,'EventAgeDays'				= DATEDIFF(d, ds.submit_date, GETDATE())
		,'Last Completed Task'		= 0
		,'DaysAgeBin306090'			= CASE 
										   WHEN DATEDIFF(d, ds.submit_date, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, ds.submit_date, GETDATE())< 60 THEN '30-59'
										   WHEN DATEDIFF(d, ds.submit_date, GETDATE())< 90 THEN '60-89'
										   WHEN DATEDIFF(d, ds.submit_date, GETDATE())> 90 THEN '>=90'
										   ELSE ''
									  END
		,'DaysAgeBin90180'			= CASE 
										   WHEN DATEDIFF(d, ds.submit_date, GETDATE())< 90 THEN '1-90'
										   WHEN DATEDIFF(d, ds.submit_date, GETDATE())< 180 THEN '91-180'
										   WHEN DATEDIFF(d, ds.submit_date, GETDATE())>= 90 THEN '180+'
										   ELSE ''
									  END
		,'lot_id'					= dl.lot_id
		,'sale_id'					= ds.sale_id
		,'job_id'					= NULL--dj.job_id
		,'Net_Revenue'				= fs.Net_Revenue
		,'SQFT'						= 0.00
		,FORMAT(ds.submit_date, 'yyyy-MM') AS MonthYear
		,YEAR(ds.submit_date) * 100 + MONTH(ds.submit_date) AS MonthYearSort
    FROM EDW_Silver.dbo.dim_lot dl
        INNER JOIN EDW_Silver.dbo.dim_project dp
            ON dp.project_id = dl.project_id
                AND dp.is_active = 'Y'
        INNER JOIN EDW_Silver.dbo.dim_operating_unit do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
            AND do.is_active = 'Y'
        INNER JOIN EDW_Silver.dbo.dim_sale ds
            ON ds.lot_id = dl.lot_id
            AND ds.is_active = 'Y'
        LEFT JOIN EDW_Silver.dbo.dim_sale_transfer dst
            ON dst.transfer_to_selection_id = ds.sale_id
            AND dst.is_active = 'y'
		LEFT JOIN EDW_Gold.dbo.vw_rep_lot_financials_summary fs
			ON fs.lot_id = dl.lot_id
    WHERE dl.exclude_from_reporting = 0
        AND dl.is_active = 'Y'
        AND ds.submit_date IS NOT NULL AND ds.approved_date IS NULL
),

Sales AS (
	--Sales Events
	SELECT DISTINCT
	--Operating dimensions that owns event
		 'UnitCode'					= dp.reporting_operating_unit_code
		,'ProjectCode'				= dp.project_code
		,'ProjectID'				= dp.project_id
		,'LotNo'					= dl.lot_number
		,'LotKey'					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number

	--Ownership Details
		,'Operating Unit Name'		= do.operating_unit_name
		,'Project Name'				= dp.project_name
		,'Lot Address'				= dl.street + CASE WHEN dl.street2 <> '' THEN ' ' + dl.street2 ELSE '' END

	--LotEvent Key
		,'LotEventKey'				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number + '|' + 'SaleEvent|' + CAST(ds.sale_id AS VARCHAR(20))

	--Event Details
		,'Event Source'				= 'NSS'
		,'Event Date'				= ds.approved_date
		,'Date'						= CAST(ds.approved_date AS DATE)
		,'Event Category'			= 'Sales'
		,'Event Type'				= CASE 
										   WHEN ds.is_transfer_to = 1 THEN dst.reason_description
										   WHEN ds.approved_date IS NOT NULL THEN 'Sale'
										   ELSE NULL
									  END
		,'Event Value'				= 1
		,'EventAgeDays'				= DATEDIFF(d, ds.approved_date, GETDATE())
		,'Last Completed Task'		= 0
		,'DaysAgeBin306090'			= CASE 
										   WHEN DATEDIFF(d, ds.approved_date, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, ds.approved_date, GETDATE()) < 60 THEN '30-59'
										   WHEN DATEDIFF(d, ds.approved_date, GETDATE()) < 90 THEN '60-89'
										   WHEN DATEDIFF(d, ds.approved_date, GETDATE()) > 90 THEN '>=90'
										   ELSE ''
									  END
		,'DaysAgeBin90180'			= CASE 
										   WHEN DATEDIFF(d, ds.approved_date, GETDATE()) < 90 THEN '1-90'
										   WHEN DATEDIFF(d, ds.approved_date, GETDATE()) < 180 THEN '91-180'
										   WHEN DATEDIFF(d, ds.approved_date, GETDATE()) >= 90 THEN '180+'
										   ELSE ''
									  END
		,'lot_id'					= dl.lot_id
		,'sale_id'					= ds.sale_id
		,'job_id'					= NULL--dj.job_id
		,'Net_Revenue'				= fs.Net_Revenue
		,'SQFT'						= fs.SQFT_from_Sale
		,FORMAT(ds.approved_date, 'yyyy-MM') AS MonthYear
		,YEAR(ds.approved_date) * 100 + MONTH(ds.approved_date) AS MonthYearSort
    FROM EDW_Silver.dbo.dim_lot dl
        INNER JOIN EDW_Silver.dbo.dim_project dp
            ON dp.project_id = dl.project_id
                AND dp.is_active = 'Y'
        INNER JOIN EDW_Silver.dbo.dim_operating_unit do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
            AND do.is_active = 'Y'
        INNER JOIN EDW_Silver.dbo.dim_sale ds
            ON ds.lot_id = dl.lot_id
            AND ds.is_active = 'Y'
        LEFT JOIN EDW_Silver.dbo.dim_sale_transfer dst
            ON dst.transfer_to_selection_id = ds.sale_id
            AND dst.is_active = 'y'
		LEFT JOIN EDW_Gold.dbo.vw_rep_lot_financials_summary fs
			ON fs.lot_id = dl.lot_id
    WHERE dl.exclude_from_reporting = 0
        AND dl.is_active = 'Y'
        AND (dl.lot_transfer_date IS NULL OR dl.lot_transfer_date > ds.approved_date)
        AND (ds.approved_date IS NOT NULL)
),
Cancels AS (
	--Cancels Events
	SELECT DISTINCT
	--Operating dimensions that owns event
		 'UnitCode'					= dp.reporting_operating_unit_code
		,'ProjectCode'				= dp.project_code
		,'ProjectID'				= dp.project_id
		,'LotNo'					= dl.lot_number
		,'LotKey'					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number

	--Ownership Details
		,'Operating Unit Name'		= do.operating_unit_name
		,'Project Name'				= dp.project_name
		,'Lot Address'				= dl.street + CASE WHEN dl.street2 <> '' THEN ' ' + dl.street2 ELSE '' END

	--LotEvent Key
		,'LotEventKey'				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number + '|' + 'CancelEvent|' + CAST(ds.sale_id AS VARCHAR(20))

	--Event Details
		,'Event Source'				= 'NSS'
		,'Event Date'				= ds.cancel_date
		,'Date'						= CAST(ds.cancel_date AS DATE)
		,'Event Category'			= 'Cancels'
		,'Event Type'				= CASE WHEN ds.is_transfer_from = 1 THEN ds.cancel_reason
										   WHEN ds.is_transfer_from = 0 THEN 'Cancel'
										   ELSE NULL
									  END
		,'Event Value'				= 1
		,'EventAgeDays'				= DATEDIFF(d, ds.cancel_date, GETDATE())
		,'Last Completed Task'		= 0
		,'DaysAgeBin306090'			= CASE 
										   WHEN DATEDIFF(d, ds.cancel_date, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, ds.cancel_date, GETDATE()) < 60 THEN '30-59'
										   WHEN DATEDIFF(d, ds.cancel_date, GETDATE()) < 90 THEN '60-89'
										   WHEN DATEDIFF(d, ds.cancel_date, GETDATE()) > 90 THEN '>=90'
										   ELSE ''
									  END
		,'DaysAgeBin90180'			= CASE 
										   WHEN DATEDIFF(d, ds.cancel_date, GETDATE()) < 90 THEN '1-90'
										   WHEN DATEDIFF(d, ds.cancel_date, GETDATE()) < 180 THEN '91-180'
										   WHEN DATEDIFF(d, ds.cancel_date, GETDATE()) >= 90 THEN '180+'
										   ELSE ''
									  END
		,'lot_id'					= dl.lot_id
		,'sale_id'					= ds.sale_id
		,'job_id'					= NULL--dj.job_id
		,'Net_Revenue'				= 0.00
		,'SQFT'						= 0.00
		,FORMAT(ds.cancel_date, 'yyyy-MM') AS MonthYear
		,YEAR(ds.cancel_date) * 100 + MONTH(ds.cancel_date) AS MonthYearSort

	FROM EDW_Silver.dbo.dim_lot dl
        INNER JOIN EDW_Silver.dbo.dim_project dp
            ON dp.project_id = dl.project_id
                AND dp.is_active = 'Y'
        INNER JOIN EDW_Silver.dbo.dim_operating_unit do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
            AND do.is_active = 'Y'
        INNER JOIN EDW_Silver.dbo.dim_sale ds
            ON ds.lot_id = dl.lot_id
            AND ds.cancel_date IS NOT NULL
            AND ds.is_active = 'Y'
    WHERE dl.exclude_from_reporting = 0
        AND dl.is_active = 'Y'
        AND (dl.lot_transfer_date IS NULL OR dl.lot_transfer_date > ds.cancel_date)
),

 Closings AS (
	--Close Events
	SELECT DISTINCT
	--Operating dimensions that owns event
		 'UnitCode'					= dp.reporting_operating_unit_code
		,'ProjectCode'				= dp.project_code
		,'ProjectID'				= dp.project_id
		,'LotNo'					= dl.lot_number
		,'LotKey'					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number

	--Ownership Details
		,'Operating Unit Name'		= do.operating_unit_name
		,'Project Name'				= dp.project_name
		,'Lot Address'				= dl.street + CASE WHEN dl.street2 <> '' THEN ' ' + dl.street2 ELSE '' END

	--LotEvent Key
		,'LotEventKey'				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number + '|' + 'ClosingEvent|' + CAST(ds.sale_id AS VARCHAR(16))

	--Event Details
		,'Event Source'				= 'NSE'
		,'Event Date'				= dl.close_date
		,'Date'						= CAST(dl.close_date AS DATE)
		,'Event Category'			= 'Closing'
		,'Event Type'				= 'Close'
		,'Event Value'				= 1
		,'EventAgeDays'				= DATEDIFF(d, dl.close_date, GETDATE())
		,'Last Completed Task'		= 0
		,'DaysAgeBin306090'			= CASE 
										   WHEN DATEDIFF(d, dl.close_date, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, dl.close_date, GETDATE()) < 60 THEN '30-59'
										   WHEN DATEDIFF(d, dl.close_date, GETDATE()) < 90 THEN '60-89'
										   WHEN DATEDIFF(d, dl.close_date, GETDATE()) > 90 THEN '>=90'
										   ELSE ''
									  END
		,'DaysAgeBin90180'			= CASE 
										   WHEN DATEDIFF(d, dl.close_date, GETDATE()) < 90 THEN '1-90'
										   WHEN DATEDIFF(d, dl.close_date, GETDATE()) < 180 THEN '91-180'
										   WHEN DATEDIFF(d, dl.close_date, GETDATE()) >= 90 THEN '180+'
										   ELSE ''
									  END
		,'lot_id'					= dl.lot_id
		,'sale_id'					= ds.sale_id
		,'job_id'					= NULL--dj.job_id
		,'Net_Revenue'				= fs.Net_Revenue
		,'SQFT'						= fs.SQFT_from_Sale
		,FORMAT(dl.close_date, 'yyyy-MM') AS MonthYear
		,YEAR(dl.close_date) * 100 + MONTH(dl.close_date) AS MonthYearSort
	FROM EDW_Silver.dbo.dim_lot dl
        INNER JOIN EDW_Silver.dbo.dim_project dp
            ON dp.project_id = dl.project_id
                AND dp.is_active = 'Y'
        INNER JOIN EDW_Silver.dbo.dim_operating_unit do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
            AND do.is_active = 'Y'
        INNER JOIN EDW_Silver.dbo.dim_sale ds
            ON CAST(ds.lot_id AS VARCHAR(50)) = dl.lot_id
            AND ds.cancel_date IS NULL
            AND ds.is_active = 'Y'
		LEFT JOIN EDW_Gold.dbo.vw_rep_lot_financials_summary fs
			ON fs.lot_id = dl.lot_id
	WHERE dl.exclude_from_reporting = 0
        AND dl.is_active = 'Y'
        AND (dl.lot_transfer_date IS NULL OR dl.lot_transfer_date > dl.close_date)
        AND dl.is_closed = 1				--Not Closed
     --   AND ds.is_active = 'Y'
),

PendingClose AS (
	--Pending Close Events
	SELECT DISTINCT
	--Operating dimensions that owns event
		 'UnitCode'					= dp.reporting_operating_unit_code
		,'ProjectCode'				= dp.project_code
		,'ProjectID'				= dp.project_id
		,'LotNo'					= dl.lot_number
		,'LotKey'					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number

	--Ownership Details
		,'Operating Unit Name'		= do.operating_unit_name
		,'Project Name'				= dp.project_name
		,'Lot Address'				= dl.street + CASE WHEN dl.street2 <> '' THEN ' ' + dl.street2 ELSE '' END

	--LotEvent Key
		,'LotEventKey'				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number + '|' + 'PendingClosingEvent|' + CAST(ds.sale_id AS VARCHAR(16))

	--Event Details
		,'Event Source'				= 'NSE'
		,'Event Date'				= dl.revised_close_date--CASE WHEN MONTH(dl.revised_close_date) < MONTH(GETDATE()) OR YEAR(dl.revised_close_date) < YEAR(GETDATE()) THEN DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) ELSE dl.revised_close_date END
		,'Date'						= CAST(dl.revised_close_date AS DATE)
		,'Event Category'			= 'Closing'
		,'Event Type'				= 'Pending Close'
		,'Event Value'				= 1
		,'EventAgeDays'				= DATEDIFF(d, dl.revised_close_date, GETDATE())
										--DATEDIFF(d, CASE WHEN MONTH(dl.revised_close_date) < MONTH(GETDATE()) OR YEAR(dl.revised_close_date) < YEAR(GETDATE()) THEN DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) ELSE dl.revised_close_date END, GETDATE())
		,'Last Completed Task'		= 0
		,'DaysAgeBin306090'			= CASE WHEN DATEDIFF(d, dl.revised_close_date, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, dl.revised_close_date, GETDATE()) < 60 THEN '30-59'
										   WHEN DATEDIFF(d, dl.revised_close_date, GETDATE()) < 90 THEN '60-89'
										   WHEN DATEDIFF(d, dl.revised_close_date, GETDATE()) > 90 THEN '>=90'
										   --WHEN DATEDIFF(d, CASE WHEN MONTH(dl.revised_close_date) < MONTH(GETDATE()) OR YEAR(dl.revised_close_date) < YEAR(GETDATE()) THEN DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) ELSE dl.revised_close_date END, GETDATE()) < 30 THEN '<30'
										   --WHEN DATEDIFF(d, CASE WHEN MONTH(dl.revised_close_date) < MONTH(GETDATE()) OR YEAR(dl.revised_close_date) < YEAR(GETDATE()) THEN DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) ELSE dl.revised_close_date END, GETDATE()) < 60 THEN '30-59'
										   --WHEN DATEDIFF(d, CASE WHEN MONTH(dl.revised_close_date) < MONTH(GETDATE()) OR YEAR(dl.revised_close_date) < YEAR(GETDATE()) THEN DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) ELSE dl.revised_close_date END, GETDATE()) < 90 THEN '60-89'
										   --WHEN DATEDIFF(d, CASE WHEN MONTH(dl.revised_close_date) < MONTH(GETDATE()) OR YEAR(dl.revised_close_date) < YEAR(GETDATE()) THEN DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) ELSE dl.revised_close_date END, GETDATE()) > 90 THEN '>=90'
										   ELSE ''
									  END
		,'DaysAgeBin90180'			= CASE WHEN DATEDIFF(d, dl.revised_close_date, GETDATE()) < 90 THEN '1-90'
										   WHEN DATEDIFF(d, dl.revised_close_date, GETDATE()) < 180 THEN '91-180'
										   WHEN DATEDIFF(d, dl.revised_close_date, GETDATE()) >= 90 THEN '180+'
										   --WHEN DATEDIFF(d, CASE WHEN MONTH(dl.revised_close_date) < MONTH(GETDATE()) OR YEAR(dl.revised_close_date) < YEAR(GETDATE()) THEN DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) ELSE dl.revised_close_date END, GETDATE()) < 90 THEN '1-90'
										   --WHEN DATEDIFF(d, CASE WHEN MONTH(dl.revised_close_date) < MONTH(GETDATE()) OR YEAR(dl.revised_close_date) < YEAR(GETDATE()) THEN DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) ELSE dl.revised_close_date END, GETDATE()) < 180 THEN '91-180'
										   --WHEN DATEDIFF(d, CASE WHEN MONTH(dl.revised_close_date) < MONTH(GETDATE()) OR YEAR(dl.revised_close_date) < YEAR(GETDATE()) THEN DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) ELSE dl.revised_close_date END, GETDATE()) >= 90 THEN '180+'
										   ELSE ''
									  END
		,'lot_id'					= dl.lot_id
		,'sale_id'					= ds.sale_id
		,'job_id'					= NULL--dj.job_id
		,'Net_Revenue'				= fs.Net_Revenue
		,'SQFT'						= fs.SQFT_from_Sale
		,FORMAT(dl.revised_close_date, 'yyyy-MM') AS MonthYear
		,YEAR(dl.revised_close_date) * 100 + MONTH(dl.revised_close_date) AS MonthYearSort
	FROM EDW_Silver.dbo.dim_lot dl
        INNER JOIN EDW_Silver.dbo.dim_project dp
            ON dp.project_id = dl.project_id
                AND dp.is_active = 'Y'
        INNER JOIN EDW_Silver.dbo.dim_operating_unit do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
            AND do.is_active = 'Y'
        INNER JOIN EDW_Silver.dbo.dim_sale ds
            ON ds.lot_id = dl.lot_id
            AND ds.cancel_date IS NULL
            AND ds.is_active = 'Y'
		LEFT JOIN EDW_Gold.dbo.vw_rep_lot_financials_summary fs
			ON fs.lot_id = dl.lot_id
	WHERE dl.exclude_from_reporting = 0
        AND dl.is_active = 'Y'
        AND dl.lot_transfer_date IS NULL 
        AND ds.approved_date IS NOT NULL
		AND dl.close_date IS NULL
        AND ds.is_active = 'Y'
)


SELECT * FROM Sales UNION ALL

SELECT * FROM Cancels UNION ALL 

SELECT * FROM Closings UNION ALL 
SELECT * FROM PendingClose UNION ALL
SELECT * FROM JobStarts UNION ALL 
SELECT * FROM BuildProTasks UNION ALL 
SELECT * FROM RevertToDirts UNION ALL 
SELECT * FROM QICEvents UNION ALL 
SELECT * FROM PendingSales 











/*
    UNION ALL
	--Manual Sales Events
	SELECT
	--Operating dimensions that owns event
		 'UnitCode'					= dp.reporting_operating_unit_code
		,'ProjectCode'				= dp.project_code
		,'ProjectID'				= dp.project_id
		,'LotNo'					= ManualData.Lot
		,'LotKey'					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + ManualData.Lot

	--Ownership Details
		,'Operating_Unit_Name'		= do.operating_unit_name
		,'Project_Name'				= dp.project_name
		,'Lot_Address'				= ManualData.[Address]

	--LotEvent Key
		,'LotEventKey'				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + ManualData.Lot + '|' + 'SaleEvent|Manual'

	
		,'SelectionID'				= NULL

	--Event Details
		,'Event Source'				= 'Manual'
		,'Event Date'				= ManualData.ContractDate
		,'Event Category'			= 'Sales'
		,'Event Type'				= 'Sale'
		,'Event Value'				= 1
		,'EventAgeDays'				= DATEDIFF(d, ManualData.ContractDate, GETDATE())
		,'Last Completed Task'		= 0
		,'DaysAgeBin306090'			= CASE 
										   WHEN DATEDIFF(d, ManualData.ContractDate, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, ManualData.ContractDate, GETDATE()) < 60 THEN '30-59'
										   WHEN DATEDIFF(d, ManualData.ContractDate, GETDATE()) < 90 THEN '60-89'
										   WHEN DATEDIFF(d, ManualData.ContractDate, GETDATE()) > 90 THEN '>=90'
										   ELSE ''
									  END
		,'DaysAgeBin90180'			= CASE 
										   WHEN DATEDIFF(d, ManualData.ContractDate, GETDATE()) < 90 THEN '1-90'
										   WHEN DATEDIFF(d, ManualData.ContractDate, GETDATE()) < 180 THEN '91-180'
										   WHEN DATEDIFF(d, ManualData.ContractDate, GETDATE()) >= 90 THEN '180+'
										   ELSE ''
									  END

	FROM [ITTOOLS].[dbo].[ManualSales] ManualData
	INNER JOIN [HBLive].[rems].[project] NSE_Project WITH (NOLOCK) ON ManualData.ounitcode = dp.reporting_operating_unit_code
		AND ManualData.ProjCode = dp.project_code
	INNER JOIN [HBLive].[rems].[operunit] NSE_UnitCode WITH (NOLOCK) ON dp.reporting_operating_unit_code = NSE_UnitCode.ounitcode
	LEFT JOIN [HBLive].[rems].[jobphase] NSE_Lots WITH (NOLOCK) ON dp.project_id = NSE_Lots.projid
		AND ManualData.Lot = NSE_Lots.phase
		
	WHERE (NSE_UnitCode.ounitcode IN (SELECT * FROM dbo.DelimitedSplitRows(@UnitCode, ',')) OR @UnitCode = '*')
		AND (dp.project_code IN (SELECT * FROM dbo.DelimitedSplitRows(@ProjectCodes, ',')) OR @ProjectCodes = '*')
		AND (@Exclude = 0 OR (NSE_Lots.userdeflog##1 = 0 AND NSE_Project.userdeflog##2 = 0))		--Exclude lots and projects marked for removal from reporting
		AND ManualData.ContractDate >= @EventStartDate
		AND ManualData.ContractDate < @DayAfterEndDate

	GROUP BY dp.reporting_operating_unit_code, dp.project_code, dp.project_id, ManualData.Lot, do.operating_unit_name, dp.project_name, ManualData.[Address], ManualData.ContractDate

    UNION ALL

	--Manual Cancel Events
	SELECT
	--Operating dimensions that owns event
		 'UnitCode'					= dp.reporting_operating_unit_code
		,'ProjectCode'				= dp.project_code
		,'ProjectID'				= dp.project_id
		,'LotNo'					= ManualData.Lot
		,'LotKey'					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + ManualData.Lot

	--Ownership Details
		,'Operating_Unit_Name'		= do.operating_unit_name
		,'Project_Name'				= dp.project_name
		,'Lot_Address'				= ManualData.[Address]

	--LotEvent Key
		,'LotEventKey'				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + ManualData.Lot + '|' + 'CancelEvent|Manual'

	
		,'SelectionID'				= NULL

	--Event Details
		,'Event Source'				= 'Manual'
		,'Event Date'				= ManualData.CancelDate
		,'Event Category'			= 'Cancels'
		,'Event Type'				= 'Cancel'
		,'Event Value'				= 1
		,'EventAgeDays'				= DATEDIFF(d, ManualData.CancelDate, GETDATE())
		,'Last Completed Task'		= 0
		,'DaysAgeBin306090'			= CASE 
										   WHEN DATEDIFF(d, ManualData.CancelDate, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, ManualData.CancelDate, GETDATE()) < 60 THEN '30-59'
										   WHEN DATEDIFF(d, ManualData.CancelDate, GETDATE()) < 90 THEN '60-89'
										   WHEN DATEDIFF(d, ManualData.CancelDate, GETDATE()) > 90 THEN '>=90'
										   ELSE ''
									  END
		,'DaysAgeBin90180'			= CASE 
										   WHEN DATEDIFF(d, ManualData.CancelDate, GETDATE()) < 90 THEN '1-90'
										   WHEN DATEDIFF(d, ManualData.CancelDate, GETDATE()) < 180 THEN '91-180'
										   WHEN DATEDIFF(d, ManualData.CancelDate, GETDATE()) >= 90 THEN '180+'
										   ELSE ''
									  END

	FROM [ITTOOLS].[dbo].[ManualSales] ManualData
	INNER JOIN EDW_Silver.dbo.dim_project dp
            ON dp.project_code = ManualData.projcode
                AND dp.is_active = 'Y'
        INNER JOIN EDW_Silver.dbo.dim_operating_unit do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
*/

