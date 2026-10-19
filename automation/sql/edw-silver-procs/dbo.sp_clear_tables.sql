CREATE PROC [dbo].[sp_clear_tables]

AS
BEGIN

TRUNCATE TABLE [EDW_Silver].[dbo].[dim_company]
TRUNCATE TABLE [EDW_Silver].[dbo].[dim_division]
TRUNCATE TABLE [EDW_Silver].[dbo].[dim_job]
TRUNCATE TABLE [EDW_Silver].[dbo].[dim_job_task]
TRUNCATE TABLE [EDW_Silver].[dbo].[dim_lot]
TRUNCATE TABLE [EDW_Silver].[dbo].[dim_major_minor]
TRUNCATE TABLE [EDW_Silver].[dbo].[dim_operating_unit]
TRUNCATE TABLE [EDW_Silver].[dbo].[dim_period]
TRUNCATE TABLE [EDW_Silver].[dbo].[dim_project]
TRUNCATE TABLE [EDW_Silver].[dbo].[dim_sale]
TRUNCATE TABLE [EDW_Silver].[dbo].[dim_sale_transfer]
TRUNCATE TABLE [EDW_Silver].[dbo].[dim_sgm_map]
TRUNCATE TABLE [EDW_Silver].[dbo].[fact_general_ledger]
TRUNCATE TABLE [EDW_Silver].[dbo].[fact_lot_financials]
TRUNCATE TABLE [EDW_Silver].[dbo].[fact_lot_sgm]
TRUNCATE TABLE [EDW_Silver].[dbo].[fact_sgm_assumptions]


END
