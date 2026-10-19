CREATE VIEW analytics.customer_survey_det AS (SELECT 
    [lot].[lot_id] AS LotId, 
    CONCAT([lot].[street], ', ', [lot].[city], ', ', [lot].[state], ' ', [lot].[zip]) AS address, 
    close_date = [lot].[close_date],
    [sale].[sale_id],
    [sale].[buyer_name], 
    [sale].[buyer_email], 
    COALESCE([buyer_cell_phone],COALESCE([buyer_home_phone],[buyer_work_phone])) as buyer_phone,
    unit.operating_unit_code,
    [unit].[operating_unit_name],
    project.project_code,
    project.project_name,
    lot.lot_number
FROM 
    analytics.sale_active AS [sale] 
INNER JOIN 
    analytics.lot_active AS [lot] ON [sale].[lot_id] = [lot].[lot_id] 
INNER JOIN 
    analytics.project_active AS [project] ON [sale].[project_id] = [project].[project_id] 
INNER JOIN 
    analytics.operating_unit_active AS [unit] ON [project].[reporting_operating_unit_code] = [unit].[operating_unit_code]
WHERE ([lot].[close_date] >= '1/1/2026' OR lot.close_date IS NULL)
    AND sale.[approved_date] IS NOT NULL
    AND sale.[cancel_date] IS NULL
    AND lot.[exclude_from_reporting] = 0
)