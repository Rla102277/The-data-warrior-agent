CREATE VIEW [dbo].[vw_dim_period]
AS 
SELECT [period_guid],
			[period_id],
			[company_code],
			[fiscal_year],
			[period],
			[period_start],
			[period_end],
			[is_closed],
			[effective_start_date],
			[effective_end_date],
			[is_active],
			[is_deleted],
			[created_date],
			[record_hash_key],
			[created_by],
			[created_job_run_id]
FROM [EDW_Silver].[dbo].[dim_period];