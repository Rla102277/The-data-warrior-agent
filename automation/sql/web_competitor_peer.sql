/*
  control.web_competitor_peer
  Named competitive peer sets (assumed competition).
  Used by Foundation Market Intelligence for head-to-head pages.

  Target: warehouse_stage. Never dbo.
*/

IF OBJECT_ID('control.web_competitor_peer') IS NULL
BEGIN
    CREATE TABLE control.web_competitor_peer
    (
        peer_set_name   VARCHAR(128)  NOT NULL,
        focal_builder   VARCHAR(128)  NOT NULL,
        peer_builder    VARCHAR(128)  NOT NULL,
        is_active       BIT           NOT NULL,
        notes           VARCHAR(512)  NULL
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'pk_web_competitor_peer'
      AND parent_object_id = OBJECT_ID('control.web_competitor_peer')
)
    ALTER TABLE control.web_competitor_peer
    ADD CONSTRAINT pk_web_competitor_peer
    PRIMARY KEY NONCLUSTERED (peer_set_name, focal_builder, peer_builder) NOT ENFORCED;
GO

MERGE control.web_competitor_peer AS t
USING (VALUES
    -- Trophy president named MTH (Meritage) as the competitor
    ('Trophy DFW peers', 'Trophy', 'Meritage', 1,
     'Trophy president callout MTH = Meritage Homes; metro-level assumed competition'),
    ('Trophy DFW peers', 'Trophy', 'Pulte', 1,
     'Same-community competition at Whitewing Trails / Parks at Wilson Creek'),
    ('Trophy DFW peers', 'Trophy', 'Highland', 1,
     'Same-community competition at Parks at Wilson Creek'),
    ('Trophy DFW peers', 'Trophy', 'Tradition', 1,
     'Same-community competition at Parks at Wilson Creek'),
    -- BridgeWater corridor peers
    ('BridgeWater peers', 'Highland', 'Perry Homes', 1,
     'BridgeWater Midlothian multi-builder market'),
    ('BridgeWater peers', 'Highland', 'Tri Pointe', 1,
     'BridgeWater Midlothian multi-builder market'),
    ('BridgeWater peers', 'Highland', 'American Legend', 1,
     'BridgeWater Midlothian multi-builder market'),
    ('BridgeWater peers', 'Highland', 'John Houston', 1,
     'BridgeWater Midlothian multi-builder market'),
    -- Legacy Hills peers
    ('Legacy Hills peers', 'Ashton Woods', 'Lennar', 1,
     'Legacy Hills multi-builder market'),
    ('Legacy Hills peers', 'Ashton Woods', 'Mattamy', 1,
     'Legacy Hills multi-builder market'),
    ('Legacy Hills peers', 'Ashton Woods', 'MI', 1,
     'Legacy Hills multi-builder market'),
    ('Legacy Hills peers', 'Ashton Woods', 'Pulte', 1,
     'Legacy Hills multi-builder market'),
    ('Legacy Hills peers', 'Ashton Woods', 'UM', 1,
     'Legacy Hills multi-builder market')
) AS s (peer_set_name, focal_builder, peer_builder, is_active, notes)
ON t.peer_set_name = s.peer_set_name
   AND t.focal_builder = s.focal_builder
   AND t.peer_builder = s.peer_builder
WHEN MATCHED THEN UPDATE SET
    is_active = s.is_active,
    notes = s.notes
WHEN NOT MATCHED THEN INSERT
    (peer_set_name, focal_builder, peer_builder, is_active, notes)
    VALUES (s.peer_set_name, s.focal_builder, s.peer_builder, s.is_active, s.notes);
GO
