 
CREATE VIEW analytics.title_communities_det AS
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
    analytics.title_booking_det; 