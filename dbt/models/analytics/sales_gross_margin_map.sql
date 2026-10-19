{{ config(materialized='view', schema='analytics', alias='sales_gross_margin_map') }}

SELECT [sgm_map_guid],
			[sgm_map_id],
			[category],
			[sub_category],
			[sgm_type],
			[description],
			[major_code],
			[major_description],
			[minor_code],
			[minor_description],
			[sgm_active],
			[lastmoddatetime],
			[effective_start_date],
			[effective_end_date],
			[is_active],
			[is_deleted],
			[created_date],
			[record_hash_key],
			[created_by],
			[created_job_run_id]
FROM {{ source('transform', 'sales_gross_margin_map') }}
WHERE is_active = 'Y'
