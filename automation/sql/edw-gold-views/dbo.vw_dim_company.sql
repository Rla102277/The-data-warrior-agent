
CREATE VIEW [dbo].[vw_dim_company]
AS 
SELECT [company_guid],
			[aid],
			[company_code],
			[name],
			[short_code],
			[street],
			[street2],
			[suite],
			[zip],
			[city],
			[state],
			[gstregno],
			[frozen],
			[lastmoddatetime],
			[effective_start_date],
			[effective_end_date],
			[is_active],
			[is_deleted],
			[created_date],
			[record_hash_key],
			[created_by],
			[created_job_run_id]
FROM [EDW_Silver].[dbo].[dim_company];