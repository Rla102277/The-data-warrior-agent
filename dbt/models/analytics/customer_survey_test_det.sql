{{ config(materialized='view', schema='analytics', alias='customer_survey_test_det', tags=['unpublished','wrapper']) }}

(SELECT 
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
    {{ ref('sale') }} AS [sale]
JOIN
    {{ ref('lot') }} AS [lot] ON [sale].[lot_id] = [lot].[lot_id]
JOIN
    {{ ref('project') }} AS [project] ON [sale].[project_id] = [project].[project_id]
JOIN
    {{ ref('operating_unit') }} AS [unit] ON [project].[reporting_operating_unit_code] = [unit].[operating_unit_code]
    WHERE [lot].[close_date] >= '1/1/2026')
