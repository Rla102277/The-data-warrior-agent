{{ config(materialized='view', schema='analytics', alias='sale_transfer') }}

SELECT   st1.[sale_transfer_guid],
			st1.[transfer_id],
			st1.[transfer_from_selection_id],
			st1.[transfer_to_selection_id],
			st1.[transfer_date],
			st1.[reason_code],
			st1.[reason_description],
			st1.[effective_start_date],
			st1.[effective_end_date],
			st1.[record_hash_key],
			st1.[is_active],
			st1.[created_date],
			st1.[created_by],
			st1.[created_job_run_id]
FROM {{ source('transform', 'sale_transfer') }} st1
