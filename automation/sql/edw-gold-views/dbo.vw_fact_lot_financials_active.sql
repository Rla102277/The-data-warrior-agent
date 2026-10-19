



CREATE VIEW [dbo].[vw_fact_lot_financials_active]
AS SELECT lf1.[lot_financials_guid],
	lf1.[lot_financials_id],
	lf1.[lot_id],
	lf1.[major_code],
	lf1.[minor_code],
	lf1.[latest_est_calc_method],
	lf1.[latest_est_method_used],
	lf1.[anchor_estimate],
	lf1.[latest_est_amount],
	lf1.[gl_amount],
	lf1.[sgm_type],
	lf1.[sgm_type_description]
FROM [EDW_Silver].[dbo].[fact_lot_financials] lf1;