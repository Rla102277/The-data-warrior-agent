CREATE PROC [transform].[sp_clear_tables]

AS
BEGIN

TRUNCATE TABLE [transform].[company]
TRUNCATE TABLE [transform].[division]
TRUNCATE TABLE [transform].[job]
TRUNCATE TABLE [transform].[job_task]
TRUNCATE TABLE [transform].[lot]
TRUNCATE TABLE [transform].[major_minor]
TRUNCATE TABLE [transform].[operating_unit]
TRUNCATE TABLE [transform].[fiscal_period]
TRUNCATE TABLE [transform].[project]
TRUNCATE TABLE [transform].[sale]
TRUNCATE TABLE [transform].[sale_transfer]
TRUNCATE TABLE [transform].[sales_gross_margin_map]
TRUNCATE TABLE [transform].[general_ledger_det]
TRUNCATE TABLE [transform].[lot_financials_det]
TRUNCATE TABLE [transform].[lot_sales_gross_margin_det]
TRUNCATE TABLE [transform].[sales_gross_margin_assumptions_det]


END
