CREATE VIEW analytics.job_active
AS SELECT   j1.[job_guid],
			j1.[project_id],
			j1.[job_id],
			j1.[lot_id],
			j1.[lot_number],
			j1.[schedule_code],
			j1.[job_status],
			j1.[construction_manager],
			[construction_manager_email] = mu1.email_address,
			j1.[planned_start_date],
			j1.[start_date],
			j1.[planned_complete_date],
			j1.[complete_date],
			j1.[revert_to_dirt_date],
			j1.[current_corp_milestone],
			j1.[current_bldr_milestone],
			j1.[job_active],
			Builder_Email = 'tgalatian@greenbrickpartners.com',
			ACM_Email = 'cgrams@greenbrickpartners.com',
			VP_Email = 'randerson@greenbrickpartners.com',
			j1.[lastmoddatetime],
			j1.[effective_start_date],
			j1.[effective_end_date],
			j1.[record_hash_key],
			j1.[is_active],
			j1.[is_deleted],
			j1.[created_date],
			j1.[created_by],
			j1.[created_job_run_id]
FROM [transform].[job] j1
INNER JOIN [transform].[lot] l1
    ON j1.lot_id = l1.lot_id
INNER JOIN BuildPro.dbo.mh4_job mj1 
	ON mj1.job_id = j1.job_id
LEFT JOIN BuildPro.dbo.mh4_user mu1 
	ON mu1.user_id = mj1.primary_user_id
WHERE 
    j1.is_active = 'Y'
    AND l1.is_active = 'Y'
    AND l1.exclude_from_reporting = 0;