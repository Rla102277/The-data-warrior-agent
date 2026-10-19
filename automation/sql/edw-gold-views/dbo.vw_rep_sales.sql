CREATE VIEW [dbo].[vw_rep_sales]
AS SELECT s1.*
FROM [EDW_Silver].[dbo].[dim_sale] s1
INNER JOIN [EDW_Silver].[dbo].[dim_lot] l1
    ON s1.lot_id = l1.lot_id
INNER JOIN [EDW_Silver].[dbo].[dim_project] p1
    ON s1.project_id = p1.project_id
INNER JOIN [EDW_Silver].[dbo].[dim_operating_unit] ou1
    ON p1.operating_unit_code = ou1.operating_unit_code
WHERE 
    s1.is_active = 'Y'
    AND l1.is_active = 'Y'
    AND p1.is_active = 'Y'
    AND ou1.is_active = 'Y'
    AND l1.exclude_from_reporting = 0

