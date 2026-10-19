{{ config(materialized='view', schema='analytics', alias='division') }}

SELECT [division_guid],
			[company_code],
			[division_id],
			[division_code],
			[name],
			[short_code],
			[subcode],
			[status],
			[lastmoddatetime],
			[effective_start_date],
			[effective_end_date],
			[is_active],
			[is_deleted],
			[created_date],
			[record_hash_key],
			[created_by],
			[created_job_run_id]
FROM {{ source('transform', 'division') }}
WHERE is_active = 'Y'
