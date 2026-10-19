{{ config(materialized='view', schema='analytics', alias='operating_unit') }}

-- Current-row operating unit. HomeBuilder folded from the former *_active twin.

SELECT   ou1.[operating_unit_guid],
			ou1.[operating_unit_code],
			ou1.[operating_unit_name],
			ou1.[operating_unit_label],
			ou1.[aid],
			ou1.[industry],
			ou1.[last_modified_by],
			ou1.[last_modified_timestamp],
			ou1.[brand_short_code],
			ou1.[region_short_code],
			ou1.[street],
			ou1.[street2],
			ou1.[suite],
			ou1.[city],
			ou1.[state],
			ou1.[zip],
			CASE WHEN ou1.[operating_unit_code] IN ('0002','0003','0004','0005','0009','0011','0013','0014','0016') THEN 1 ELSE 0 END [HomeBuilder],
			ou1.[lastmoddatetime],
			ou1.[effective_start_date],
			ou1.[effective_end_date],
			ou1.[record_hash_key],
			ou1.[is_active],
			ou1.[is_deleted],
			ou1.[created_date],
			ou1.[created_by],
			ou1.[created_job_run_id]
FROM {{ source('transform', 'operating_unit') }} ou1
WHERE ou1.is_active = 'Y'
