/*
  control.web_peer_project
  Peer community <-> GBP project links for Foundation Market Intelligence.
  Landed from Dataverse gbp_gbppeercommunities (Web API). That entity is not
  on the Enterprise Dataverse lakehouse sync used by FD shortcuts.

  Target: warehouse_stage. Never dbo.
*/

IF OBJECT_ID('control.web_peer_project') IS NULL
BEGIN
    CREATE TABLE control.web_peer_project
    (
        peer_link_id            VARCHAR(64)   NOT NULL,
        link_name               VARCHAR(256)  NULL,
        peer_community_id       VARCHAR(64)   NULL,
        peer_community_name     VARCHAR(256)  NULL,
        internal_project_id     VARCHAR(64)   NULL,
        internal_project_label  VARCHAR(256)  NULL,
        project_code            VARCHAR(64)   NULL,
        project_name            VARCHAR(256)  NULL,
        operating_unit_code     VARCHAR(64)   NULL,
        match_score             FLOAT         NULL,
        match_reasons           VARCHAR(1024) NULL,
        match_source            VARCHAR(128)  NULL,
        match_run_id            VARCHAR(128)  NULL,
        is_active               BIT           NOT NULL,
        synced_at               DATETIME2(6)  NOT NULL
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'pk_web_peer_project'
      AND parent_object_id = OBJECT_ID('control.web_peer_project')
)
    ALTER TABLE control.web_peer_project
    ADD CONSTRAINT pk_web_peer_project
    PRIMARY KEY NONCLUSTERED (peer_link_id) NOT ENFORCED;
GO

-- One-time migrate from interim VT-named land if present
IF OBJECT_ID('control.web_project_vt_peer') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM control.web_peer_project)
BEGIN
    INSERT INTO control.web_peer_project (
        peer_link_id, link_name, peer_community_id, peer_community_name,
        internal_project_id, internal_project_label,
        project_code, project_name, operating_unit_code,
        match_score, match_reasons, match_source, match_run_id,
        is_active, synced_at
    )
    SELECT
        peer_link_id, link_name, peer_community_id, peer_community_name,
        internal_project_id, internal_project_label,
        project_code, project_name, operating_unit_code,
        match_score, match_reasons, match_source, match_run_id,
        is_active, synced_at
    FROM control.web_project_vt_peer;
END
GO
