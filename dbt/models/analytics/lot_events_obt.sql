{{ config(materialized='view', schema='analytics', alias='lot_events_obt') }}

/*
  Operations report model. Grain: one row per lot-event (lot_event_key).
  Snake_case columns. Operating unit name/short code from transform.operating_unit
  (no hardcoded ounit CASE). Display labels belong in the semantic model.
*/

WITH JobStarts AS (
    --Job Start Events
	SELECT DISTINCT
	--Operating dimensions that owns event
		 operating_unit_code					= dp.reporting_operating_unit_code
		,project_code				= dp.project_code
		,project_id				= dp.project_id
		,lot_number					= dl.lot_number
		,lot_key					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number

	--Ownership Details
		,operating_unit_name		= do.operating_unit_name
		,project_name				= dp.project_name
		,lot_address				= dl.street + CASE WHEN dl.street2 <> '' THEN ' ' + dl.street2 ELSE '' END

	--LotEvent Key
		,lot_event_key				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number + '|StartEvent|NSE'

	--Event Details
		,event_source				= 'BuildPro/NSE'
		,event_date				= dj.start_date 
		,event_date_day						= CAST(dj.start_date  AS DATE)
		,event_category			= 'Starts'
		,event_type				= '1-Job Started'
		,event_value				= 1
		,event_age_days				= DATEDIFF(d, dj.start_date, GETDATE())
		,last_completed_task		= CASE WHEN dj.current_corp_milestone = 1 THEN 1 ELSE 0 END
		,days_age_bin_30_60_90			= CASE 
										   WHEN DATEDIFF(d, dj.start_date, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, dj.start_date, GETDATE()) < 60 THEN '30-59'
										   WHEN DATEDIFF(d, dj.start_date, GETDATE()) < 90 THEN '60-89'
										   WHEN DATEDIFF(d, dj.start_date, GETDATE()) > 90 THEN '>=90'
										   ELSE ''
									  END
		,days_age_bin_90_180			= CASE 
										   WHEN DATEDIFF(d, dj.start_date, GETDATE()) < 90 THEN '1-90'
										   WHEN DATEDIFF(d, dj.start_date, GETDATE()) < 180 THEN '91-180'
										   WHEN DATEDIFF(d, dj.start_date, GETDATE()) >= 90 THEN '180+'
										   ELSE ''
									  END
		,lot_id					= dl.lot_id
		,sale_id					= NULL--ds.sale_id
		,job_id					= dj.job_id
		,net_revenue				= 0.00
		,sqft						= 0.00
		,FORMAT(dj.start_date, 'yyyy-MM') AS month_year
		,YEAR(dj.start_date) * 100 + MONTH(dj.start_date) AS month_year_sort
   FROM {{ source('transform', 'lot') }} dl
        INNER JOIN {{ source('transform', 'project') }} dp
            ON dp.project_id = dl.project_id
                AND dp.is_active = 'Y'
        INNER JOIN {{ source('transform', 'operating_unit') }} do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
            AND do.is_active = 'Y'
        INNER JOIN {{ source('transform', 'job') }} dj
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
		 operating_unit_code					= dp.reporting_operating_unit_code
		,project_code				= dp.project_code
		,project_id				= dp.project_id
		,lot_number					= dl.lot_number
		,lot_key					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number

	--Ownership Details
		,operating_unit_name		= do.operating_unit_name
		,project_name				= dp.project_name
		,lot_address				= dl.street + CASE WHEN dl.street2 <> '' THEN ' ' + dl.street2 ELSE '' END

	--LotEvent Key
		,lot_event_key				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number + '|TaskEvent|' + djt.task_code + '|' + CAST(djt.task_id AS VARCHAR(10))
	
	--Event Details
		,event_source				= 'BuildPro'
		,event_date				= djt.actual_end_date
		,event_date_day						= CAST(djt.actual_end_date AS DATE)
		,event_category			= 'Tasks'
		,event_type				= CASE WHEN djt.task_code = '00PRDTST'  THEN 'Pending Start'
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
		,event_value				= 1
		,event_age_days				= DATEDIFF(d, djt.actual_end_date, GETDATE())
		,last_completed_task		= CASE WHEN djt.corp_milestone_num = dj.current_corp_milestone THEN 1 ELSE 0 END
		,days_age_bin_30_60_90			= CASE 
										   WHEN DATEDIFF(d, djt.actual_end_date, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, djt.actual_end_date, GETDATE()) < 60 THEN '30-59'
										   WHEN DATEDIFF(d, djt.actual_end_date, GETDATE()) < 90 THEN '60-89'
										   WHEN DATEDIFF(d, djt.actual_end_date, GETDATE()) >= 90 THEN '>=90'
										   ELSE ''
									  END
		,days_age_bin_90_180			= CASE 
										   WHEN DATEDIFF(d, djt.actual_end_date, GETDATE()) < 90 THEN '1-90'
										   WHEN DATEDIFF(d, djt.actual_end_date, GETDATE()) < 180 THEN '91-180'
										   WHEN DATEDIFF(d, djt.actual_end_date, GETDATE()) >= 90 THEN '180+'
										   ELSE ''
									  END
		,lot_id					= dl.lot_id
		,sale_id					= NULL--ds.sale_id
		,job_id					= dj.job_id
		,net_revenue				= 0.00
		,sqft						= 0.00
		,FORMAT(djt.actual_end_date, 'yyyy-MM') AS month_year
		,YEAR(djt.actual_end_date) * 100 + MONTH(djt.actual_end_date) AS month_year_sort
	FROM {{ source('transform', 'lot') }} dl
        INNER JOIN {{ source('transform', 'project') }} dp
            ON dp.project_id = dl.project_id
                AND dp.is_active = 'Y'
        INNER JOIN {{ source('transform', 'operating_unit') }} do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
            AND do.is_active = 'Y'
        LEFT JOIN {{ source('transform', 'job') }} dj
            ON dj.lot_id = dl.lot_id
            AND dj.is_active = 'Y'
            AND dj.job_active = 1
        INNER JOIN {{ source('transform', 'job_task') }} djt
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
		 operating_unit_code					= dp.reporting_operating_unit_code
		,project_code				= dp.project_code
		,project_id				= dp.project_id
		,lot_number					= dl.lot_number
		,lot_key					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number

	--Ownership Details
		,operating_unit_name		= do.operating_unit_name
		,project_name				= dp.project_name
		,lot_address				= dl.street + CASE WHEN dl.street2 <> '' THEN ' ' + dl.street2 ELSE '' END

	--LotEvent Key
		,lot_event_key				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number + '|StartEvent|NSE'

	--Event Details
		,event_source				= 'NSE'
		,event_date				= dj.revert_to_dirt_date 
		,event_date_day						= CAST(dj.revert_to_dirt_date  AS DATE)
		,event_category			= 'Starts'
		,event_type				= 'Revert to Dirt'
		,event_value				= 1
		,event_age_days				= DATEDIFF(d, dj.revert_to_dirt_date, GETDATE())
		,last_completed_task		= CASE WHEN dj.current_corp_milestone = 1 THEN 1 ELSE 0 END
		,days_age_bin_30_60_90			= CASE 
										   WHEN DATEDIFF(d, dj.revert_to_dirt_date, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, dj.revert_to_dirt_date, GETDATE()) < 60 THEN '30-59'
										   WHEN DATEDIFF(d, dj.revert_to_dirt_date, GETDATE()) < 90 THEN '60-89'
										   WHEN DATEDIFF(d, dj.revert_to_dirt_date, GETDATE()) > 90 THEN '>=90'
										   ELSE ''
									  END
		,days_age_bin_90_180			= CASE 
										   WHEN DATEDIFF(d, dj.revert_to_dirt_date, GETDATE()) < 90 THEN '1-90'
										   WHEN DATEDIFF(d, dj.revert_to_dirt_date, GETDATE()) < 180 THEN '91-180'
										   WHEN DATEDIFF(d, dj.revert_to_dirt_date, GETDATE()) >= 90 THEN '180+'
										   ELSE ''
									  END
		,lot_id					= dl.lot_id
		,sale_id					= NULL--ds.sale_id
		,job_id					= dj.job_id
		,net_revenue				= 0.00
		,sqft						= 0.00
		,FORMAT(dj.revert_to_dirt_date, 'yyyy-MM') AS month_year
		,YEAR(dj.revert_to_dirt_date) * 100 + MONTH(dj.revert_to_dirt_date) AS month_year_sort
   FROM {{ source('transform', 'lot') }} dl
        INNER JOIN {{ source('transform', 'project') }} dp
            ON dp.project_id = dl.project_id
                AND dp.is_active = 'Y'
        INNER JOIN {{ source('transform', 'operating_unit') }} do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
            AND do.is_active = 'Y'
        INNER JOIN {{ source('transform', 'job') }} dj
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
		 operating_unit_code					= dp.reporting_operating_unit_code
		,project_code				= dp.project_code
		,project_id				= dp.project_id
		,lot_number					= dl.lot_number
		,lot_key					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number

	--Ownership Details
		,operating_unit_name		= do.operating_unit_name
		,project_name				= dp.project_name
		,lot_address				= dl.street + CASE WHEN dl.street2 <> '' THEN ' ' + dl.street2 ELSE '' END

	--LotEvent Key
		,lot_event_key				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number + '|QIEvent|NSE'

	--Event Details
		,event_source				= 'BuildPro/NSE'
		,event_date				= dj.complete_date
		,event_date_day						= CAST(dj.complete_date AS DATE)
		,event_category			= 'Tasks'
		,event_type				= '9-QI/Job'
		,event_value				= 1
		,event_age_days				= DATEDIFF(d,dj.complete_date, GETDATE())
		,last_completed_task		= 1
		,days_age_bin_30_60_90			= CASE 
										   WHEN DATEDIFF(d, dj.complete_date, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, dj.complete_date, GETDATE()) < 60 THEN '30-59'
										   WHEN DATEDIFF(d, dj.complete_date, GETDATE()) < 90 THEN '60-89'
										   WHEN DATEDIFF(d, dj.complete_date, GETDATE()) > 90 THEN '>=90'
										   ELSE ''
									  END
		,days_age_bin_90_180			= CASE 
										   WHEN DATEDIFF(d, dj.complete_date, GETDATE()) < 90 THEN '1-90'
										   WHEN DATEDIFF(d, dj.complete_date, GETDATE()) < 180 THEN '91-180'
										   WHEN DATEDIFF(d, dj.complete_date, GETDATE()) >= 90 THEN '180+'
										   ELSE ''
									  END
		,lot_id					= dl.lot_id
		,sale_id					= NULL--ds.sale_id
		,job_id					= dj.job_id
		,net_revenue				= 0.00
		,sqft						= 0.00
		,FORMAT(dj.complete_date, 'yyyy-MM') AS month_year
		,YEAR(dj.complete_date) * 100 + MONTH(dj.complete_date) AS month_year_sort
    FROM {{ source('transform', 'lot') }} dl
        INNER JOIN {{ source('transform', 'project') }} dp
            ON dp.project_id = dl.project_id
                AND dp.is_active = 'Y'
        INNER JOIN {{ source('transform', 'operating_unit') }} do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
            AND do.is_active = 'Y'
        INNER JOIN {{ source('transform', 'job') }} dj
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
		 operating_unit_code					= dp.reporting_operating_unit_code
		,project_code				= dp.project_code
		,project_id				= dp.project_id
		,lot_number					= dl.lot_number
		,lot_key					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number

	--Ownership Details
		,operating_unit_name		= do.operating_unit_name
		,project_name				= dp.project_name
		,lot_address				= dl.street + CASE WHEN dl.street2 <> '' THEN ' ' + dl.street2 ELSE '' END

	--LotEvent Key
		,lot_event_key				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number + '|' + 'SaleEvent|' + CAST(ds.sale_id AS VARCHAR(20))

	--Event Details
		,event_source				= 'NSS'
		,event_date				= ds.submit_date
		,event_date_day						= CAST(ds.submit_date AS DATE)
		,event_category			= 'Sales'
		,event_type				= 'Pending Sale'
		,event_value				= 1
		,event_age_days				= DATEDIFF(d, ds.submit_date, GETDATE())
		,last_completed_task		= 0
		,days_age_bin_30_60_90			= CASE 
										   WHEN DATEDIFF(d, ds.submit_date, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, ds.submit_date, GETDATE())< 60 THEN '30-59'
										   WHEN DATEDIFF(d, ds.submit_date, GETDATE())< 90 THEN '60-89'
										   WHEN DATEDIFF(d, ds.submit_date, GETDATE())> 90 THEN '>=90'
										   ELSE ''
									  END
		,days_age_bin_90_180			= CASE 
										   WHEN DATEDIFF(d, ds.submit_date, GETDATE())< 90 THEN '1-90'
										   WHEN DATEDIFF(d, ds.submit_date, GETDATE())< 180 THEN '91-180'
										   WHEN DATEDIFF(d, ds.submit_date, GETDATE())>= 90 THEN '180+'
										   ELSE ''
									  END
		,lot_id					= dl.lot_id
		,sale_id					= ds.sale_id
		,job_id					= NULL--dj.job_id
		,net_revenue				= fs.net_revenue
		,sqft						= 0.00
		,FORMAT(ds.submit_date, 'yyyy-MM') AS month_year
		,YEAR(ds.submit_date) * 100 + MONTH(ds.submit_date) AS month_year_sort
    FROM {{ source('transform', 'lot') }} dl
        INNER JOIN {{ source('transform', 'project') }} dp
            ON dp.project_id = dl.project_id
                AND dp.is_active = 'Y'
        INNER JOIN {{ source('transform', 'operating_unit') }} do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
            AND do.is_active = 'Y'
        INNER JOIN {{ source('transform', 'sale') }} ds
            ON ds.lot_id = dl.lot_id
            AND ds.is_active = 'Y'
        LEFT JOIN {{ source('transform', 'sale_transfer') }} dst
            ON dst.transfer_to_selection_id = ds.sale_id
            AND dst.is_active = 'y'
		LEFT JOIN {{ ref('lot_financials_obt') }} fs
			ON fs.lot_id = dl.lot_id
    WHERE dl.exclude_from_reporting = 0
        AND dl.is_active = 'Y'
        AND ds.submit_date IS NOT NULL AND ds.approved_date IS NULL
),

Sales AS (
	--Sales Events
	SELECT DISTINCT
	--Operating dimensions that owns event
		 operating_unit_code					= dp.reporting_operating_unit_code
		,project_code				= dp.project_code
		,project_id				= dp.project_id
		,lot_number					= dl.lot_number
		,lot_key					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number

	--Ownership Details
		,operating_unit_name		= do.operating_unit_name
		,project_name				= dp.project_name
		,lot_address				= dl.street + CASE WHEN dl.street2 <> '' THEN ' ' + dl.street2 ELSE '' END

	--LotEvent Key
		,lot_event_key				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number + '|' + 'SaleEvent|' + CAST(ds.sale_id AS VARCHAR(20))

	--Event Details
		,event_source				= 'NSS'
		,event_date				= ds.approved_date
		,event_date_day						= CAST(ds.approved_date AS DATE)
		,event_category			= 'Sales'
		,event_type				= CASE 
										   WHEN ds.is_transfer_to = 1 THEN dst.reason_description
										   WHEN ds.approved_date IS NOT NULL THEN 'Sale'
										   ELSE NULL
									  END
		,event_value				= 1
		,event_age_days				= DATEDIFF(d, ds.approved_date, GETDATE())
		,last_completed_task		= 0
		,days_age_bin_30_60_90			= CASE 
										   WHEN DATEDIFF(d, ds.approved_date, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, ds.approved_date, GETDATE()) < 60 THEN '30-59'
										   WHEN DATEDIFF(d, ds.approved_date, GETDATE()) < 90 THEN '60-89'
										   WHEN DATEDIFF(d, ds.approved_date, GETDATE()) > 90 THEN '>=90'
										   ELSE ''
									  END
		,days_age_bin_90_180			= CASE 
										   WHEN DATEDIFF(d, ds.approved_date, GETDATE()) < 90 THEN '1-90'
										   WHEN DATEDIFF(d, ds.approved_date, GETDATE()) < 180 THEN '91-180'
										   WHEN DATEDIFF(d, ds.approved_date, GETDATE()) >= 90 THEN '180+'
										   ELSE ''
									  END
		,lot_id					= dl.lot_id
		,sale_id					= ds.sale_id
		,job_id					= NULL--dj.job_id
		,net_revenue				= fs.net_revenue
		,sqft						= fs.sqft
		,FORMAT(ds.approved_date, 'yyyy-MM') AS month_year
		,YEAR(ds.approved_date) * 100 + MONTH(ds.approved_date) AS month_year_sort
    FROM {{ source('transform', 'lot') }} dl
        INNER JOIN {{ source('transform', 'project') }} dp
            ON dp.project_id = dl.project_id
                AND dp.is_active = 'Y'
        INNER JOIN {{ source('transform', 'operating_unit') }} do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
            AND do.is_active = 'Y'
        INNER JOIN {{ source('transform', 'sale') }} ds
            ON ds.lot_id = dl.lot_id
            AND ds.is_active = 'Y'
        LEFT JOIN {{ source('transform', 'sale_transfer') }} dst
            ON dst.transfer_to_selection_id = ds.sale_id
            AND dst.is_active = 'y'
		LEFT JOIN {{ ref('lot_financials_obt') }} fs
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
		 operating_unit_code					= dp.reporting_operating_unit_code
		,project_code				= dp.project_code
		,project_id				= dp.project_id
		,lot_number					= dl.lot_number
		,lot_key					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number

	--Ownership Details
		,operating_unit_name		= do.operating_unit_name
		,project_name				= dp.project_name
		,lot_address				= dl.street + CASE WHEN dl.street2 <> '' THEN ' ' + dl.street2 ELSE '' END

	--LotEvent Key
		,lot_event_key				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number + '|' + 'CancelEvent|' + CAST(ds.sale_id AS VARCHAR(20))

	--Event Details
		,event_source				= 'NSS'
		,event_date				= ds.cancel_date
		,event_date_day						= CAST(ds.cancel_date AS DATE)
		,event_category			= 'Cancels'
		,event_type				= CASE WHEN ds.is_transfer_from = 1 THEN ds.cancel_reason
										   WHEN ds.is_transfer_from = 0 THEN 'Cancel'
										   ELSE NULL
									  END
		,event_value				= 1
		,event_age_days				= DATEDIFF(d, ds.cancel_date, GETDATE())
		,last_completed_task		= 0
		,days_age_bin_30_60_90			= CASE 
										   WHEN DATEDIFF(d, ds.cancel_date, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, ds.cancel_date, GETDATE()) < 60 THEN '30-59'
										   WHEN DATEDIFF(d, ds.cancel_date, GETDATE()) < 90 THEN '60-89'
										   WHEN DATEDIFF(d, ds.cancel_date, GETDATE()) > 90 THEN '>=90'
										   ELSE ''
									  END
		,days_age_bin_90_180			= CASE 
										   WHEN DATEDIFF(d, ds.cancel_date, GETDATE()) < 90 THEN '1-90'
										   WHEN DATEDIFF(d, ds.cancel_date, GETDATE()) < 180 THEN '91-180'
										   WHEN DATEDIFF(d, ds.cancel_date, GETDATE()) >= 90 THEN '180+'
										   ELSE ''
									  END
		,lot_id					= dl.lot_id
		,sale_id					= ds.sale_id
		,job_id					= NULL--dj.job_id
		,net_revenue				= 0.00
		,sqft						= 0.00
		,FORMAT(ds.cancel_date, 'yyyy-MM') AS month_year
		,YEAR(ds.cancel_date) * 100 + MONTH(ds.cancel_date) AS month_year_sort

	FROM {{ source('transform', 'lot') }} dl
        INNER JOIN {{ source('transform', 'project') }} dp
            ON dp.project_id = dl.project_id
                AND dp.is_active = 'Y'
        INNER JOIN {{ source('transform', 'operating_unit') }} do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
            AND do.is_active = 'Y'
        INNER JOIN {{ source('transform', 'sale') }} ds
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
		 operating_unit_code					= dp.reporting_operating_unit_code
		,project_code				= dp.project_code
		,project_id				= dp.project_id
		,lot_number					= dl.lot_number
		,lot_key					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number

	--Ownership Details
		,operating_unit_name		= do.operating_unit_name
		,project_name				= dp.project_name
		,lot_address				= dl.street + CASE WHEN dl.street2 <> '' THEN ' ' + dl.street2 ELSE '' END

	--LotEvent Key
		,lot_event_key				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number + '|' + 'ClosingEvent|' + CAST(ds.sale_id AS VARCHAR(16))

	--Event Details
		,event_source				= 'NSE'
		,event_date				= dl.close_date
		,event_date_day						= CAST(dl.close_date AS DATE)
		,event_category			= 'Closing'
		,event_type				= 'Close'
		,event_value				= 1
		,event_age_days				= DATEDIFF(d, dl.close_date, GETDATE())
		,last_completed_task		= 0
		,days_age_bin_30_60_90			= CASE 
										   WHEN DATEDIFF(d, dl.close_date, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, dl.close_date, GETDATE()) < 60 THEN '30-59'
										   WHEN DATEDIFF(d, dl.close_date, GETDATE()) < 90 THEN '60-89'
										   WHEN DATEDIFF(d, dl.close_date, GETDATE()) > 90 THEN '>=90'
										   ELSE ''
									  END
		,days_age_bin_90_180			= CASE 
										   WHEN DATEDIFF(d, dl.close_date, GETDATE()) < 90 THEN '1-90'
										   WHEN DATEDIFF(d, dl.close_date, GETDATE()) < 180 THEN '91-180'
										   WHEN DATEDIFF(d, dl.close_date, GETDATE()) >= 90 THEN '180+'
										   ELSE ''
									  END
		,lot_id					= dl.lot_id
		,sale_id					= ds.sale_id
		,job_id					= NULL--dj.job_id
		,net_revenue				= fs.net_revenue
		,sqft						= fs.sqft
		,FORMAT(dl.close_date, 'yyyy-MM') AS month_year
		,YEAR(dl.close_date) * 100 + MONTH(dl.close_date) AS month_year_sort
	FROM {{ source('transform', 'lot') }} dl
        INNER JOIN {{ source('transform', 'project') }} dp
            ON dp.project_id = dl.project_id
                AND dp.is_active = 'Y'
        INNER JOIN {{ source('transform', 'operating_unit') }} do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
            AND do.is_active = 'Y'
        INNER JOIN {{ source('transform', 'sale') }} ds
            ON CAST(ds.lot_id AS VARCHAR(50)) = dl.lot_id
            AND ds.cancel_date IS NULL
            AND ds.is_active = 'Y'
		LEFT JOIN {{ ref('lot_financials_obt') }} fs
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
		 operating_unit_code					= dp.reporting_operating_unit_code
		,project_code				= dp.project_code
		,project_id				= dp.project_id
		,lot_number					= dl.lot_number
		,lot_key					= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number

	--Ownership Details
		,operating_unit_name		= do.operating_unit_name
		,project_name				= dp.project_name
		,lot_address				= dl.street + CASE WHEN dl.street2 <> '' THEN ' ' + dl.street2 ELSE '' END

	--LotEvent Key
		,lot_event_key				= dp.reporting_operating_unit_code + '|' + dp.project_code + '|' + dl.lot_number + '|' + 'PendingClosingEvent|' + CAST(ds.sale_id AS VARCHAR(16))

	--Event Details
		,event_source				= 'NSE'
		,event_date				= dl.revised_close_date--CASE WHEN MONTH(dl.revised_close_date) < MONTH(GETDATE()) OR YEAR(dl.revised_close_date) < YEAR(GETDATE()) THEN DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) ELSE dl.revised_close_date END
		,event_date_day						= CAST(dl.revised_close_date AS DATE)
		,event_category			= 'Closing'
		,event_type				= 'Pending Close'
		,event_value				= 1
		,event_age_days				= DATEDIFF(d, dl.revised_close_date, GETDATE())
										--DATEDIFF(d, CASE WHEN MONTH(dl.revised_close_date) < MONTH(GETDATE()) OR YEAR(dl.revised_close_date) < YEAR(GETDATE()) THEN DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) ELSE dl.revised_close_date END, GETDATE())
		,last_completed_task		= 0
		,days_age_bin_30_60_90			= CASE WHEN DATEDIFF(d, dl.revised_close_date, GETDATE()) < 30 THEN '<30'
										   WHEN DATEDIFF(d, dl.revised_close_date, GETDATE()) < 60 THEN '30-59'
										   WHEN DATEDIFF(d, dl.revised_close_date, GETDATE()) < 90 THEN '60-89'
										   WHEN DATEDIFF(d, dl.revised_close_date, GETDATE()) > 90 THEN '>=90'
										   --WHEN DATEDIFF(d, CASE WHEN MONTH(dl.revised_close_date) < MONTH(GETDATE()) OR YEAR(dl.revised_close_date) < YEAR(GETDATE()) THEN DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) ELSE dl.revised_close_date END, GETDATE()) < 30 THEN '<30'
										   --WHEN DATEDIFF(d, CASE WHEN MONTH(dl.revised_close_date) < MONTH(GETDATE()) OR YEAR(dl.revised_close_date) < YEAR(GETDATE()) THEN DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) ELSE dl.revised_close_date END, GETDATE()) < 60 THEN '30-59'
										   --WHEN DATEDIFF(d, CASE WHEN MONTH(dl.revised_close_date) < MONTH(GETDATE()) OR YEAR(dl.revised_close_date) < YEAR(GETDATE()) THEN DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) ELSE dl.revised_close_date END, GETDATE()) < 90 THEN '60-89'
										   --WHEN DATEDIFF(d, CASE WHEN MONTH(dl.revised_close_date) < MONTH(GETDATE()) OR YEAR(dl.revised_close_date) < YEAR(GETDATE()) THEN DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) ELSE dl.revised_close_date END, GETDATE()) > 90 THEN '>=90'
										   ELSE ''
									  END
		,days_age_bin_90_180			= CASE WHEN DATEDIFF(d, dl.revised_close_date, GETDATE()) < 90 THEN '1-90'
										   WHEN DATEDIFF(d, dl.revised_close_date, GETDATE()) < 180 THEN '91-180'
										   WHEN DATEDIFF(d, dl.revised_close_date, GETDATE()) >= 90 THEN '180+'
										   --WHEN DATEDIFF(d, CASE WHEN MONTH(dl.revised_close_date) < MONTH(GETDATE()) OR YEAR(dl.revised_close_date) < YEAR(GETDATE()) THEN DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) ELSE dl.revised_close_date END, GETDATE()) < 90 THEN '1-90'
										   --WHEN DATEDIFF(d, CASE WHEN MONTH(dl.revised_close_date) < MONTH(GETDATE()) OR YEAR(dl.revised_close_date) < YEAR(GETDATE()) THEN DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) ELSE dl.revised_close_date END, GETDATE()) < 180 THEN '91-180'
										   --WHEN DATEDIFF(d, CASE WHEN MONTH(dl.revised_close_date) < MONTH(GETDATE()) OR YEAR(dl.revised_close_date) < YEAR(GETDATE()) THEN DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()) ELSE dl.revised_close_date END, GETDATE()) >= 90 THEN '180+'
										   ELSE ''
									  END
		,lot_id					= dl.lot_id
		,sale_id					= ds.sale_id
		,job_id					= NULL--dj.job_id
		,net_revenue				= fs.net_revenue
		,sqft						= fs.sqft
		,FORMAT(dl.revised_close_date, 'yyyy-MM') AS month_year
		,YEAR(dl.revised_close_date) * 100 + MONTH(dl.revised_close_date) AS month_year_sort
	FROM {{ source('transform', 'lot') }} dl
        INNER JOIN {{ source('transform', 'project') }} dp
            ON dp.project_id = dl.project_id
                AND dp.is_active = 'Y'
        INNER JOIN {{ source('transform', 'operating_unit') }} do
            ON do.operating_unit_code = dp.reporting_operating_unit_code
            AND do.is_active = 'Y'
        INNER JOIN {{ source('transform', 'sale') }} ds
            ON ds.lot_id = dl.lot_id
            AND ds.cancel_date IS NULL
            AND ds.is_active = 'Y'
		LEFT JOIN {{ ref('lot_financials_obt') }} fs
			ON fs.lot_id = dl.lot_id
	WHERE dl.exclude_from_reporting = 0
        AND dl.is_active = 'Y'
        AND dl.lot_transfer_date IS NULL 
        AND ds.approved_date IS NOT NULL
		AND dl.close_date IS NULL
        AND ds.is_active = 'Y'
)


SELECT
    base.operating_unit_code AS operating_unit_code,
    COALESCE(ou.operating_unit_name, base.operating_unit_name) AS operating_unit_name,
    ou.brand_short_code AS operating_unit_short_code,
    base.project_code AS project_code,
    base.project_id AS project_id,
    base.lot_number AS lot_number,
    base.lot_key AS lot_key,
    base.project_name AS project_name,
    base.lot_address AS lot_address,
    base.lot_event_key AS lot_event_key,
    base.event_source AS event_source,
    base.event_date AS event_date,
    CAST(base.event_date_day AS DATE) AS event_date_day,
    base.event_category AS event_category,
    base.event_type AS event_type,
    base.event_value AS event_value,
    base.event_age_days AS event_age_days,
    base.last_completed_task AS last_completed_task,
    base.days_age_bin_30_60_90 AS days_age_bin_30_60_90,
    base.days_age_bin_90_180 AS days_age_bin_90_180,
    base.lot_id,
    base.sale_id,
    base.job_id,
    CAST(base.net_revenue AS DECIMAL(18,2)) AS net_revenue,
    CAST(base.sqft AS DECIMAL(18,2)) AS sqft,
    cal.week_start_date,
    cal.week_end_date,
    cal.year AS calendar_year,
    cal.month AS calendar_month,
    DATEFROMPARTS(cal.year, cal.month, 1) AS month_start
FROM (
    SELECT * FROM Sales UNION ALL
    SELECT * FROM Cancels UNION ALL
    SELECT * FROM Closings UNION ALL
    SELECT * FROM PendingClose UNION ALL
    SELECT * FROM JobStarts UNION ALL
    SELECT * FROM BuildProTasks UNION ALL
    SELECT * FROM RevertToDirts UNION ALL
    SELECT * FROM QICEvents UNION ALL
    SELECT * FROM PendingSales
) AS base
LEFT JOIN {{ source('transform', 'operating_unit') }} ou
    ON ou.operating_unit_code = base.operating_unit_code
    AND ou.is_active = 'Y'
LEFT JOIN {{ source('transform', 'calendar') }} cal
    ON cal.full_date = CAST(base.event_date_day AS DATE)
