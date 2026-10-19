CREATE VIEW dbo.vw_fact_lot_financials
AS SELECT lot_financials_guid, 
lot_financials_id, 
lot_id, 
major_code, 
minor_code, 
latest_est_calc_method, 
latest_est_method_used, 
anchor_estimate, 
latest_est_amount, 
gl_amount, 
sgm_type, 
sgm_type_description, 
lastmoddatetime, 
created_date, 
record_hash_key, 
created_by, 
created_job_run_id 
FROM [EDW_Silver].[dbo].[fact_lot_financials];