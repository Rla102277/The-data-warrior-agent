/*
  control.web_community_project_map
  Hand map: scrape community -> ERP analytics.project.
  control.web_gbp_builder
  Builder aliases that count as GBP on website scrape (gbp_web side).

  Target: warehouse_stage (Foundation Development). Never dbo.
*/

IF OBJECT_ID('control.web_gbp_builder') IS NULL
BEGIN
    CREATE TABLE control.web_gbp_builder
    (
        builder_alias VARCHAR(128) NOT NULL,
        builder_name  VARCHAR(128) NULL,
        is_active     BIT          NOT NULL,
        notes         VARCHAR(512) NULL
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'pk_web_gbp_builder'
      AND parent_object_id = OBJECT_ID('control.web_gbp_builder')
)
    ALTER TABLE control.web_gbp_builder
    ADD CONSTRAINT pk_web_gbp_builder
    PRIMARY KEY NONCLUSTERED (builder_alias) NOT ENFORCED;
GO

MERGE control.web_gbp_builder AS t
USING (VALUES
    ('CB JENI Homes', 'CB JENI Homes', 1, 'ERP OU 0003; Dataverse gbp_builder'),
    ('CB JENI', 'CB JENI Homes', 1, 'short match'),
    ('Highland Homes', 'Highland Homes', 1, 'GBP portfolio; not in FD ERP OU list'),
    ('American Legend Homes', 'American Legend Homes', 1, 'GBP portfolio'),
    ('American Legend', 'American Legend Homes', 1, 'short match'),
    ('Coventry Homes', 'Coventry Homes', 1, 'GBP portfolio'),
    ('Britton Homes', 'Britton Homes', 1, 'GBP portfolio'),
    ('John Houston Homes', 'John Houston Homes', 1, 'GBP portfolio'),
    ('John Houston', 'John Houston Homes', 1, 'short match'),
    ('Southgate Homes', 'Southgate Homes', 1, 'ERP OU 0005'),
    ('Normandy Homes', 'Normandy Homes', 1, 'ERP OU 0013'),
    ('Trophy Signature Homes', 'Trophy Signature Homes', 1, 'ERP OU 0011/0014/0016'),
    ('Centre Living Homes', 'Centre Living Homes', 1, 'ERP OU 0004'),
    ('GHO Homes', 'GHO Homes', 1, 'ERP OU 0009'),
    ('The Providence Group', 'The Providence Group', 1, 'ERP OU 0002')
) AS s (builder_alias, builder_name, is_active, notes)
ON t.builder_alias = s.builder_alias
WHEN MATCHED THEN UPDATE SET
    builder_name = s.builder_name,
    is_active = s.is_active,
    notes = s.notes
WHEN NOT MATCHED THEN INSERT (builder_alias, builder_name, is_active, notes)
VALUES (s.builder_alias, s.builder_name, s.is_active, s.notes);
GO

IF OBJECT_ID('control.web_community_project_map') IS NULL
BEGIN
    CREATE TABLE control.web_community_project_map
    (
        source_group   VARCHAR(64)    NOT NULL,
        community_name VARCHAR(128)   NOT NULL,
        project_id     VARCHAR(32)    NOT NULL,
        project_name   VARCHAR(256)   NULL,
        is_active      BIT            NOT NULL,
        notes          VARCHAR(512)   NULL
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'pk_web_community_project_map'
      AND parent_object_id = OBJECT_ID('control.web_community_project_map')
)
    ALTER TABLE control.web_community_project_map
    ADD CONSTRAINT pk_web_community_project_map
    PRIMARY KEY NONCLUSTERED (source_group, community_name, project_id) NOT ENFORCED;
GO

/*
  Confirmed 2026-08-26 against analytics.project / lot_obt:
    CB JENI Midtowne project_id 00011506 (31 lots). 00011638 is a twin with 0 lots.
  2026-09-15 Market Intelligence MVP:
    Whitewing Trails 50 (00011262), Wilson Creek 50 (00011358) nearest ERP matches.
  BridgeWater / Star Trail / Legacy Hills / Treeline: no ERP project name match in FD yet
  (web-only sides until Ops confirms project_id).
*/
MERGE control.web_community_project_map AS t
USING (VALUES
    ('village-at-midtowne', 'The Village at Midtowne', '00011506',
     'CB JENI Midtowne', 1,
     'Confirmed lot_obt 31 lots; SGM base_revenue on lot_financials_obt'),
    ('whitewing-trails', 'Whitewing Trails', '00011262',
     'Whitewing Trails 50', 1,
     'Market Intelligence MVP map; confirm phase with Ops'),
    ('parks-at-wilson-creek', 'Parks at Wilson Creek', '00011358',
     'Wilson Creek 50', 1,
     'Market Intelligence MVP nearest ERP match; confirm with Ops')
) AS s (source_group, community_name, project_id, project_name, is_active, notes)
ON t.source_group = s.source_group
   AND t.community_name = s.community_name
   AND t.project_id = s.project_id
WHEN MATCHED THEN UPDATE SET
    project_name = s.project_name,
    is_active = s.is_active,
    notes = s.notes
WHEN NOT MATCHED THEN INSERT
    (source_group, community_name, project_id, project_name, is_active, notes)
VALUES
    (s.source_group, s.community_name, s.project_id, s.project_name, s.is_active, s.notes);
GO
