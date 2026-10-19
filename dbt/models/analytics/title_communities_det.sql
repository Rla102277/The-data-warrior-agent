{{ config(materialized='view', schema='analytics', alias='title_communities_det') }}

SELECT DISTINCT
    [project_name],
    [operating_unit_name],
    CONVERT(
        UNIQUEIDENTIFIER,
        SUBSTRING(
            HASHBYTES('SHA2_256',
                CONCAT(
                    ISNULL([project_name], ''),
                    '|',
                    ISNULL([operating_unit_name], '')
                )
            ), 1, 16
        )
    ) AS [community_guid]
FROM
    {{ ref('title_booking_obt') }}
