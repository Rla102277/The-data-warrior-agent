/*
  control.web_community_geo
  Community centroids for proximity competitive sets.
  Grain: source_group + community_name.
  Seed via automation/seed_web_community_geo.py (Nominatim + ERP address when mapped).
  Manual overrides: set geo_method = 'manual', raise geo_confidence.

  Target: warehouse_stage (Foundation Development). Never dbo.
*/

IF OBJECT_ID('control.web_community_geo') IS NULL
BEGIN
    CREATE TABLE control.web_community_geo
    (
        source_group     VARCHAR(64)     NOT NULL,
        community_name   VARCHAR(128)    NOT NULL,
        city             VARCHAR(64)     NULL,
        state            VARCHAR(16)     NULL,
        zip              VARCHAR(16)     NULL,
        latitude         FLOAT           NOT NULL,
        longitude        FLOAT           NOT NULL,
        geo_method       VARCHAR(32)     NOT NULL,
        geo_confidence   VARCHAR(16)     NOT NULL,
        geocode_query    VARCHAR(512)    NULL,
        is_gbp_focal     BIT             NOT NULL,
        notes            VARCHAR(512)    NULL,
        updated_at       DATETIME2(0)    NOT NULL
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'pk_web_community_geo'
      AND parent_object_id = OBJECT_ID('control.web_community_geo')
)
    ALTER TABLE control.web_community_geo
    ADD CONSTRAINT pk_web_community_geo
    PRIMARY KEY NONCLUSTERED (source_group, community_name) NOT ENFORCED;
GO
