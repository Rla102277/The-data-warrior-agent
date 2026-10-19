CREATE VIEW analytics.customer_survey_test_det AS (SELECT 
    [lot].[lot_id] AS LotId, 
    CONCAT([lot].[street], ', ', [lot].[city], ', ', [lot].[state], ' ', [lot].[zip]) AS address, 
    [lot].[close_date], [sale].[sale_id],
    [sale].[buyer_name], 
    --[sale].[buyer_email], 
    buyer_email = CASE [unit].[operating_unit_code] 
                        WHEN '0002' THEN 'tcaldwell@theprovidencegroup.com'
                        WHEN '0003' THEN 'CWilcocks@cbjenihomes.com'
                        WHEN '0004' THEN 'tbrickman@centrelivinghomes.com'
                        WHEN '0005' THEN 'smccurdy@cbjenihomes.com'
                        WHEN '0009' THEN 'tonyv@ghohomes.com'
                        WHEN '0011' THEN 'cwicker@trophysignaturehomes.com'
                        --WHEN '0013' THEN 'nmarshall@cbjenihomes.com'
                        ELSE  'randerson@greenbrickpartners.com' END, 
    [unit].[operating_unit_name] 
FROM 
    analytics.sale_active AS [sale] 
JOIN 
    analytics.lot_active AS [lot] ON [sale].[lot_id] = [lot].[lot_id] 
JOIN 
    analytics.project_active AS [project] ON [sale].[project_id] = [project].[project_id] 
JOIN 
    analytics.operating_unit_active AS [unit] ON [project].[reporting_operating_unit_code] = [unit].[operating_unit_code]
    WHERE [lot].[close_date] >= '1/1/2026')