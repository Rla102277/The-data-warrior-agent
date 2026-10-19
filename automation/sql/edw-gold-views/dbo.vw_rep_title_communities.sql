 
CREATE VIEW [dbo].[vw_rep_title_communities] AS
SELECT DISTINCT
    [Project_Name],
    [Operating_Name],
    CONVERT(
        UNIQUEIDENTIFIER,
        SUBSTRING(
            HASHBYTES('SHA2_256', 
                CONCAT(
                    ISNULL([Project_Name], ''), 
                    '|', 
                    ISNULL([Operating_Name], '')
                )
            ), 1, 16
        )
    ) AS [CommunityGUID]
FROM
    [dbo].[vw_rep_title_booking]; 