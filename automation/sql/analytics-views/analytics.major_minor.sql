CREATE VIEW analytics.major_minor
AS 
SELECT [major_minor_guid],
			[major_minor_id],
			[job_type],
			[major_code],
			[major_description],
			[minor_code],
			[minor_description],
			[major_active],
			[minor_active],
			[lastmoddatetime],
			[effective_start_date],
			[effective_end_date],
			[is_active],
			[is_deleted],
			[created_date],
			[record_hash_key],
			[created_by],
			[created_job_run_id]
FROM [transform].[major_minor];