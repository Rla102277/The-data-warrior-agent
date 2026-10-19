/*
  control.web_scrape_source
  Target: warehouse_stage (Foundation Development)
  dbo is not used. Allowed target schemas: raw, stage, control, transform, analytics.

  Add a site:
    INSERT into this table (is_active = 1). Set create_table_if_missing = 1
    so the next notebook_web_scrape run creates
    warehouse_stage.<target_schema>.<target_table> from the shape template.

  Companion: knowledge/operations/web-scrape-setup.md
*/

CREATE OR ALTER PROCEDURE control.sp_ensure_web_scrape_table
    @target_schema VARCHAR(32),
    @target_table  VARCHAR(128),
    @table_shape   VARCHAR(16)
AS
BEGIN
    SET NOCOUNT ON;

    IF @target_schema IS NULL OR @target_table IS NULL OR @table_shape IS NULL
        THROW 50001, 'target_schema, target_table, and table_shape are required.', 1;

    IF LOWER(@target_schema) = 'dbo'
        THROW 50002, 'dbo is not allowed. Use raw, stage, control, transform, or analytics.', 1;

    IF LOWER(@target_schema) NOT IN ('raw', 'stage', 'control', 'transform', 'analytics')
        THROW 50003, 'target_schema must be raw, stage, control, transform, or analytics.', 1;

    IF @target_table LIKE 'dim[_]%' OR @target_table LIKE 'fact[_]%' OR @target_table LIKE 'vw[_]%'
        THROW 50004, 'dim_, fact_, and vw_ prefixes are banned.', 1;

    IF CHARINDEX('.', @target_table) > 0
        THROW 50005, 'target_table must be a table name only, not schema.table.', 1;

    IF LOWER(@table_shape) NOT IN ('page', 'listing', 'json')
        THROW 50006, 'table_shape must be page, listing, or json.', 1;

    DECLARE @full NVARCHAR(300) = QUOTENAME(@target_schema) + N'.' + QUOTENAME(@target_table);
    DECLARE @sql  NVARCHAR(MAX);

    IF OBJECT_ID(@target_schema + '.' + @target_table) IS NOT NULL
        RETURN;

    IF LOWER(@table_shape) = 'page'
        SET @sql = N'CREATE TABLE ' + @full + N' (
            run_id           VARCHAR(36)    NOT NULL,
            ingest_date      DATE           NOT NULL,
            ingested_at      DATETIME2(0)   NOT NULL,
            source_name      VARCHAR(64)    NOT NULL,
            source_url       VARCHAR(1000)  NOT NULL,
            page_title       VARCHAR(512)   NULL,
            status_code      INT            NULL,
            scraper          VARCHAR(32)    NOT NULL,
            scrape_ok        CHAR(1)        NOT NULL,
            markdown_chars   INT            NULL,
            markdown         VARCHAR(MAX)   NULL,
            error_message    VARCHAR(1000)  NULL,
            raw_path         VARCHAR(512)   NULL
        );';
    ELSE IF LOWER(@table_shape) = 'listing'
        SET @sql = N'CREATE TABLE ' + @full + N' (
            builder_name             VARCHAR(128)   NULL,
            community_name           VARCHAR(128)   NULL,
            record_type              VARCHAR(32)    NULL,
            plan_name                VARCHAR(64)    NULL,
            elevation                VARCHAR(32)    NULL,
            plan_number              VARCHAR(32)    NULL,
            price                    INT            NULL,
            starting_price           INT            NULL,
            square_feet              INT            NULL,
            bedrooms                 INT            NULL,
            bathrooms                DECIMAL(6,2)   NULL,
            stories                  INT            NULL,
            garage_spaces            INT            NULL,
            lot_size                 VARCHAR(32)    NULL,
            address                  VARCHAR(256)   NULL,
            availability_status      VARCHAR(64)    NULL,
            estimated_move_in_date   VARCHAR(64)    NULL,
            listing_url              VARCHAR(1000)  NULL,
            plan_url                 VARCHAR(1000)  NULL,
            run_id                   VARCHAR(36)    NOT NULL,
            ingest_date              DATE           NOT NULL,
            ingested_at              DATETIME2(0)   NOT NULL,
            scraper                  VARCHAR(32)    NOT NULL,
            source_name              VARCHAR(64)    NOT NULL,
            source_group             VARCHAR(64)    NULL
        );';
    ELSE
        SET @sql = N'CREATE TABLE ' + @full + N' (
            run_id         VARCHAR(36)    NOT NULL,
            ingest_date    DATE           NOT NULL,
            ingested_at    DATETIME2(0)   NOT NULL,
            source_name    VARCHAR(64)    NOT NULL,
            source_url     VARCHAR(1000)  NOT NULL,
            scraper        VARCHAR(32)    NOT NULL,
            payload        VARCHAR(MAX)   NULL
        );';

    EXEC (@sql);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'control'
      AND o.name = 'web_scrape_source'
      AND c.name = 'scrape_tier'
)
    ALTER TABLE control.web_scrape_source ADD scrape_tier VARCHAR(16) NULL;
GO
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'control'
      AND o.name = 'web_scrape_source'
      AND c.name = 'strategic_rank'
)
    ALTER TABLE control.web_scrape_source ADD strategic_rank INT NULL;
GO
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'control'
      AND o.name = 'web_scrape_source'
      AND c.name = 'heartbeat_ttl_hours'
)
    ALTER TABLE control.web_scrape_source ADD heartbeat_ttl_hours INT NULL;
GO
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'control'
      AND o.name = 'web_scrape_source'
      AND c.name = 'last_success_at'
)
    ALTER TABLE control.web_scrape_source ADD last_success_at DATETIME2(0) NULL;
GO
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'control'
      AND o.name = 'web_scrape_source'
      AND c.name = 'last_complete_at'
)
    ALTER TABLE control.web_scrape_source ADD last_complete_at DATETIME2(0) NULL;
GO
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'control'
      AND o.name = 'web_scrape_source'
      AND c.name = 'content_fingerprint'
)
    ALTER TABLE control.web_scrape_source ADD content_fingerprint VARCHAR(64) NULL;
GO
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'control'
      AND o.name = 'web_scrape_source'
      AND c.name = 'defer_reason'
)
    ALTER TABLE control.web_scrape_source ADD defer_reason VARCHAR(128) NULL;
GO
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'control'
      AND o.name = 'web_scrape_source'
      AND c.name = 'last_deferred_at'
)
    ALTER TABLE control.web_scrape_source ADD last_deferred_at DATETIME2(0) NULL;
GO

UPDATE control.web_scrape_source
SET scraper = CASE
        WHEN LOWER(COALESCE(target_table, '')) = 'web_page_det' THEN 'html_page'
        ELSE COALESCE(scraper, 'html_extract')
    END,
    scrape_tier = CASE
        WHEN LOWER(COALESCE(source_url, '')) LIKE '%jome.com%' THEN 't1_browser'
        WHEN LOWER(COALESCE(source_url, '')) LIKE '%perryhomes.com%' THEN 't1_browser'
        WHEN LOWER(COALESCE(source_url, '')) LIKE '%brittonhomestexas.com%' THEN 't1_browser'
        ELSE COALESCE(scrape_tier, 't0_html')
    END,
    heartbeat_ttl_hours = COALESCE(heartbeat_ttl_hours, 24)
WHERE 1 = 1;
GO

/* Strategic BETA scope (3-week set). Rank 1 = must be green before widening.
   Source list: automation/web_scrape/strategic_scope.json */
UPDATE control.web_scrape_source
SET strategic_rank = CASE
    WHEN source_group IN (
        'anna-town-square', 'legacy-hills', 'parks-at-wilson-creek',
        'ribbonwood', 'treeline-justin', 'treeline',
        'bridgewater-midlothian', 'perry-homes-bridgewater',
        'star-trail-prosper', 'star-trail',
        'wellington', 'highland-lakes', 'whitewing-trails',
        'village-at-midtowne', 'jome-bridgewater-midlothian'
    ) THEN 1
    ELSE COALESCE(strategic_rank, 5)
END
WHERE is_active = 1;
GO

IF EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'control'
      AND o.name = 'web_scrape_run_det'
      AND c.name = 'jobs_deferred'
)
BEGIN
    PRINT 'control.web_scrape_run_det.jobs_deferred already exists';
END
ELSE
BEGIN
    ALTER TABLE control.web_scrape_run_det ADD jobs_deferred INT NULL;
END
GO

IF OBJECT_ID('control.web_scrape_defer_det') IS NULL
BEGIN
    CREATE TABLE control.web_scrape_defer_det
    (
        defer_id      VARCHAR(36)   NOT NULL,
        logged_at     DATETIME2(0)  NOT NULL,
        source_group  VARCHAR(64)   NULL,
        source_name   VARCHAR(64)   NULL,
        listing_url   VARCHAR(1000) NULL,
        host_name     VARCHAR(128)  NULL,
        adapter       VARCHAR(64)   NULL,
        reason_code   VARCHAR(128)  NOT NULL,
        detail_json   VARCHAR(MAX)  NULL
    );
END
GO

IF OBJECT_ID('control.web_scrape_heartbeat_det') IS NULL
BEGIN
    CREATE TABLE control.web_scrape_heartbeat_det
    (
        heartbeat_id        VARCHAR(36)   NOT NULL,
        checked_at          DATETIME2(0)  NOT NULL,
        source_group        VARCHAR(64)   NOT NULL,
        source_name         VARCHAR(64)   NOT NULL,
        host_name           VARCHAR(128)  NULL,
        status_code         VARCHAR(32)   NOT NULL,
        fingerprint_before  VARCHAR(64)   NULL,
        fingerprint_after   VARCHAR(64)   NULL,
        listing_count       INT           NULL,
        queue_reason        VARCHAR(64)   NULL,
        detail_json         VARCHAR(MAX)  NULL
    );
END
GO

IF OBJECT_ID('control.web_scrape_queue') IS NULL
BEGIN
    CREATE TABLE control.web_scrape_queue
    (
        queue_id        VARCHAR(36)   NOT NULL,
        queued_at       DATETIME2(0)  NOT NULL,
        source_group    VARCHAR(64)   NOT NULL,
        source_name     VARCHAR(64)   NOT NULL,
        host_name       VARCHAR(128)  NULL,
        queue_reason    VARCHAR(64)   NOT NULL,
        run_tier        VARCHAR(16)   NOT NULL,
        queue_status    VARCHAR(32)   NOT NULL,
        requested_by    VARCHAR(64)   NOT NULL,
        detail_json     VARCHAR(MAX)  NULL
    );
END
GO

CREATE OR ALTER PROCEDURE control.sp_refresh_web_scrape_heartbeat
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @checked_at DATETIME2(0) = SYSUTCDATETIME();

    IF OBJECT_ID('tempdb..#latest_rows') IS NOT NULL
        DROP TABLE #latest_rows;

    SELECT
        d.source_group,
        d.source_name,
        COUNT(*) AS listing_count,
        CONVERT(VARCHAR(64), HASHBYTES(
            'SHA2_256',
            STRING_AGG(
                CONCAT(
                    COALESCE(d.record_type, ''), '|',
                    COALESCE(d.address, ''), '|',
                    COALESCE(d.plan_name, ''), '|',
                    COALESCE(d.plan_number, ''), '|',
                    COALESCE(CONVERT(VARCHAR(32), d.price), ''), '|',
                    COALESCE(CONVERT(VARCHAR(32), d.starting_price), ''), '|',
                    COALESCE(d.availability_status, '')
                ),
                '||'
            ) WITHIN GROUP (
                ORDER BY
                    COALESCE(d.record_type, ''),
                    COALESCE(d.address, ''),
                    COALESCE(d.plan_name, ''),
                    COALESCE(d.plan_number, '')
            )
        ), 2) AS fingerprint_after,
        MAX(d.ingested_at) AS max_ingested_at
    INTO #latest_rows
    FROM raw.web_listing_det d
    WHERE d.ingested_at = (
        SELECT MAX(x.ingested_at)
        FROM raw.web_listing_det x
        WHERE x.source_group = d.source_group
          AND x.source_name = d.source_name
    )
    GROUP BY d.source_group, d.source_name;

    ;WITH source_cfg AS (
        SELECT
            s.source_group,
            s.source_name,
            s.source_url,
            s.listing_url,
            s.scrape_tier,
            COALESCE(s.heartbeat_ttl_hours, 24) AS heartbeat_ttl_hours,
            s.content_fingerprint,
            s.last_complete_at,
            LOWER(
                LEFT(
                    REPLACE(
                        REPLACE(
                            COALESCE(
                                NULLIF(s.listing_url, ''),
                                NULLIF(s.source_url, ''),
                                ''
                            ),
                            'https://', ''
                        ),
                        'http://', ''
                    ),
                    CHARINDEX(
                        '/',
                        REPLACE(
                            REPLACE(
                                COALESCE(
                                    NULLIF(s.listing_url, ''),
                                    NULLIF(s.source_url, ''),
                                    ''
                                ),
                                'https://', ''
                            ),
                            'http://', ''
                        ) + '/'
                    ) - 1
                )
            ) AS host_name
        FROM control.web_scrape_source s
        WHERE s.is_active = 1
          AND COALESCE(s.scrape_mode, s.table_shape) IN ('listing', 'both')
    )
    INSERT INTO control.web_scrape_heartbeat_det (
        heartbeat_id, checked_at, source_group, source_name, host_name,
        status_code, fingerprint_before, fingerprint_after, listing_count,
        queue_reason, detail_json
    )
    SELECT
        CONVERT(VARCHAR(36), NEWID()),
        @checked_at,
        s.source_group,
        s.source_name,
        s.host_name,
        CASE
            WHEN l.source_group IS NULL THEN 'stale_missing'
            WHEN s.content_fingerprint IS NULL THEN 'first_fingerprint'
            WHEN s.content_fingerprint <> l.fingerprint_after THEN 'changed'
            WHEN s.last_complete_at IS NULL THEN 'stale_missing'
            WHEN DATEADD(HOUR, s.heartbeat_ttl_hours, s.last_complete_at) < @checked_at THEN 'stale_ttl'
            ELSE 'ok_unchanged'
        END,
        s.content_fingerprint,
        l.fingerprint_after,
        l.listing_count,
        CASE
            WHEN l.source_group IS NULL THEN 'first_seen'
            WHEN s.content_fingerprint IS NULL THEN 'first_seen'
            WHEN s.content_fingerprint <> l.fingerprint_after THEN 'fingerprint_changed'
            WHEN s.last_complete_at IS NULL THEN 'stale'
            WHEN DATEADD(HOUR, s.heartbeat_ttl_hours, s.last_complete_at) < @checked_at THEN 'stale'
            ELSE NULL
        END,
        CONCAT(
            '{\"scrape_tier\":\"', COALESCE(s.scrape_tier, ''), '\",',
            '\"last_complete_at\":\"', COALESCE(CONVERT(VARCHAR(19), s.last_complete_at, 120), ''), '\",',
            '\"latest_ingested_at\":\"', COALESCE(CONVERT(VARCHAR(19), l.max_ingested_at, 120), ''), '\"}'
        )
    FROM source_cfg s
    LEFT JOIN #latest_rows l
      ON l.source_group = s.source_group
     AND l.source_name = s.source_name;

    UPDATE s
    SET s.content_fingerprint = l.fingerprint_after,
        s.last_complete_at = COALESCE(l.max_ingested_at, s.last_complete_at)
    FROM control.web_scrape_source s
    INNER JOIN #latest_rows l
      ON l.source_group = s.source_group
     AND l.source_name = s.source_name;
END
GO

CREATE OR ALTER PROCEDURE control.sp_seed_web_scrape_queue
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH latest AS (
        SELECT *
        FROM (
            SELECT
                h.*,
                ROW_NUMBER() OVER (
                    PARTITION BY h.source_group, h.source_name
                    ORDER BY h.checked_at DESC, h.heartbeat_id DESC
                ) AS rn
            FROM control.web_scrape_heartbeat_det h
        ) x
        WHERE x.rn = 1
          AND x.queue_reason IS NOT NULL
    )
    INSERT INTO control.web_scrape_queue (
        queue_id, queued_at, source_group, source_name, host_name, queue_reason,
        run_tier, queue_status, requested_by, detail_json
    )
    SELECT
        CONVERT(VARCHAR(36), NEWID()),
        SYSUTCDATETIME(),
        l.source_group,
        l.source_name,
        l.host_name,
        l.queue_reason,
        COALESCE(s.scrape_tier, 't0_html'),
        'pending',
        'heartbeat',
        l.detail_json
    FROM latest l
    INNER JOIN control.web_scrape_source s
      ON s.source_group = l.source_group
     AND s.source_name = l.source_name
    WHERE NOT EXISTS (
        SELECT 1
        FROM control.web_scrape_queue q
        WHERE q.source_group = l.source_group
          AND q.source_name = l.source_name
          AND q.queue_status IN ('pending', 'running')
    );
END
GO

IF OBJECT_ID('control.web_scrape_source') IS NULL
BEGIN
    CREATE TABLE control.web_scrape_source
    (
        source_group             VARCHAR(64)    NOT NULL,
        source_name              VARCHAR(64)    NOT NULL,
        source_url               VARCHAR(1000)  NOT NULL,
        scraper                  VARCHAR(32)    NOT NULL,
        extract_prompt           VARCHAR(MAX)   NULL,
        wait_for_text            VARCHAR(128)   NULL,
        target_schema            VARCHAR(32)    NOT NULL,
        target_table             VARCHAR(128)   NOT NULL,
        table_shape              VARCHAR(16)    NOT NULL,
        create_table_if_missing  BIT            NOT NULL,
        files_prefix             VARCHAR(256)   NOT NULL,
        is_active                BIT            NOT NULL,
        notes                    VARCHAR(512)   NULL,
        community_name           VARCHAR(128)   NULL,
        builder_name             VARCHAR(128)   NULL,
        scrape_mode              VARCHAR(16)    NULL,
        listing_url              VARCHAR(1000)  NULL
    );
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'control'
      AND o.name = 'web_scrape_source'
      AND c.name = 'community_name'
)
    ALTER TABLE control.web_scrape_source ADD community_name VARCHAR(128) NULL;
GO
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'control'
      AND o.name = 'web_scrape_source'
      AND c.name = 'builder_name'
)
    ALTER TABLE control.web_scrape_source ADD builder_name VARCHAR(128) NULL;
GO
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'control'
      AND o.name = 'web_scrape_source'
      AND c.name = 'scrape_mode'
)
    ALTER TABLE control.web_scrape_source ADD scrape_mode VARCHAR(16) NULL;
GO
IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'control'
      AND o.name = 'web_scrape_source'
      AND c.name = 'listing_url'
)
    ALTER TABLE control.web_scrape_source ADD listing_url VARCHAR(1000) NULL;
GO

UPDATE control.web_scrape_source
SET community_name = COALESCE(community_name, 'Green Brick Partners'),
    builder_name = COALESCE(builder_name, 'Green Brick Partners')
WHERE source_group = 'greenbrick-partners';

UPDATE control.web_scrape_source
SET community_name = COALESCE(community_name, 'Bridgewater'),
    builder_name = COALESCE(builder_name, 'Perry Homes')
WHERE source_group = 'perry-homes-bridgewater';
GO

IF EXISTS (
    SELECT 1
    FROM sys.key_constraints
    WHERE name = 'pk_web_scrape_source'
      AND parent_object_id = OBJECT_ID('control.web_scrape_source')
)
    ALTER TABLE control.web_scrape_source DROP CONSTRAINT pk_web_scrape_source;
GO

ALTER TABLE control.web_scrape_source
ADD CONSTRAINT pk_web_scrape_source
PRIMARY KEY NONCLUSTERED (source_group, source_url, source_name) NOT ENFORCED;
GO

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'greenbrick-partners'
      AND source_url = 'https://www.greenbrickpartners.com/'
      AND builder_name = 'Green Brick Partners'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('greenbrick-partners', 'greenbrick-partners',
 'https://www.greenbrickpartners.com/',
 'firecrawl', NULL, NULL,
 'raw', 'web_page_det', 'page', 1, 'Files/web/greenbrick-partners/',
 1, 'GBP public homepage spike', 'Green Brick Partners', 'Green Brick Partners');

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'perry-homes-bridgewater'
      AND source_url = 'https://www.perryhomes.com/new-homes/texas/dallas/bridgewater/bridgewater-60'
      AND builder_name = 'Perry Homes'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('perry-homes-bridgewater', 'bridgewater-60',
 'https://www.perryhomes.com/new-homes/texas/dallas/bridgewater/bridgewater-60',
 'apify_playwright', NULL, 'Sq. Ft.',
 'raw', 'web_listing_det', 'listing', 1, 'Files/web/perry-homes-bridgewater/',
 1, 'Perry Homes Bridgewater 60 ft collection', 'Bridgewater', 'Perry Homes');

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'perry-homes-bridgewater'
      AND source_url = 'https://www.perryhomes.com/new-homes/texas/dallas/bridgewater/bridgewater-70-80'
      AND builder_name = 'Perry Homes'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('perry-homes-bridgewater', 'bridgewater-70-80',
 'https://www.perryhomes.com/new-homes/texas/dallas/bridgewater/bridgewater-70-80',
 'apify_playwright', NULL, 'Sq. Ft.',
 'raw', 'web_listing_det', 'listing', 1, 'Files/web/perry-homes-bridgewater/',
 1, 'Perry Homes Bridgewater 70/80 ft collection', 'Bridgewater', 'Perry Homes');
GO

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'bridgewater-midlothian'
      AND source_url = 'https://www.highlandhomes.com/dfw/midlothian/bridgewater'
      AND source_name = 'highland-homes'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('bridgewater-midlothian', 'highland-homes',
 'https://www.highlandhomes.com/dfw/midlothian/bridgewater',
 'apify_playwright', NULL, 'Quick Move-in',
 'raw', 'web_listing_det', 'listing', 1, 'Files/web/bridgewater-midlothian/',
 1, 'Highland Homes BridgeWater Midlothian builder community page',
 'BridgeWater', 'Highland Homes');
GO

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'bridgewater-midlothian'
      AND source_url = 'https://www.tripointehomes.com/tx/dallas-fort-worth/bridgewater'
      AND source_name = 'tripointe-discovery'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('bridgewater-midlothian', 'tripointe-discovery',
 'https://www.tripointehomes.com/tx/dallas-fort-worth/bridgewater',
 'apify_playwright', NULL, 'Move-in Ready',
 'raw', 'web_listing_det', 'listing', 1, 'Files/web/bridgewater-midlothian/',
 1, 'Tri Pointe Discovery Collection (50 ft) at BridgeWater Midlothian',
 'BridgeWater', 'Tri Pointe Homes');

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'bridgewater-midlothian'
      AND source_url = 'https://www.tripointehomes.com/tx/dallas-fort-worth/bridgewater'
      AND source_name = 'tripointe-inspiration'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('bridgewater-midlothian', 'tripointe-inspiration',
 'https://www.tripointehomes.com/tx/dallas-fort-worth/bridgewater',
 'apify_playwright', NULL, 'Move-in Ready',
 'raw', 'web_listing_det', 'listing', 1, 'Files/web/bridgewater-midlothian/',
 1, 'Tri Pointe Inspiration Collection (60 ft) at BridgeWater Midlothian',
 'BridgeWater', 'Tri Pointe Homes');
GO

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'bridgewater-midlothian'
      AND source_url = 'https://www.amlegendhomes.com/communities/texas/midlothian/bridgewater'
      AND source_name = 'american-legend-homes'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('bridgewater-midlothian', 'american-legend-homes',
 'https://www.amlegendhomes.com/communities/texas/midlothian/bridgewater',
 'apify_playwright', NULL, 'Quick Move-In',
 'raw', 'web_listing_det', 'listing', 1, 'Files/web/bridgewater-midlothian/',
 1, 'American Legend Homes BridgeWater Midlothian builder community page',
 'BridgeWater', 'American Legend Homes');

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'bridgewater-midlothian'
      AND source_url = 'https://jhoustonhomes.com/community/bridgewater/'
      AND source_name = 'john-houston-homes'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('bridgewater-midlothian', 'john-houston-homes',
 'https://jhoustonhomes.com/community/bridgewater/',
 'apify_playwright', NULL, 'Available Now',
 'raw', 'web_listing_det', 'listing', 1, 'Files/web/bridgewater-midlothian/',
 1, 'John Houston Homes Bridgewater Midlothian community page',
 'BridgeWater', 'John Houston Homes');
GO

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'village-at-midtowne'
      AND source_url = 'https://cbjenihomes.com/communities/the-village-at-midtowne/'
      AND source_name = 'cb-jeni-homes'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('village-at-midtowne', 'cb-jeni-homes',
 'https://cbjenihomes.com/communities/the-village-at-midtowne/',
 'apify_playwright', NULL, 'Quick Move-in Homes',
 'raw', 'web_listing_det', 'listing', 1, 'Files/web/village-at-midtowne/',
 1, 'CB JENI Homes The Village at Midtowne; QMI and floorplans on the community page',
 'The Village at Midtowne', 'CB JENI Homes');
GO

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'jome-bridgewater-midlothian'
      AND source_name = 'jome'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name, scrape_mode, listing_url)
VALUES
('jome-bridgewater-midlothian', 'jome',
 'https://jome.com/master-planned-community/tx/69-bridgewater',
 'apify_playwright', NULL, 'Available homes',
 'raw', 'web_aggregator_det', 'listing', 1, 'Files/web/jome-bridgewater-midlothian/',
 1, 'Jome BridgeWater Midlothian hub; secondary source only. Follows /community/tx/*bridgewater*midlothian* children. Never writes to web_listing_det.',
 'BridgeWater', 'Jome', 'listing',
 'https://jome.com/master-planned-community/tx/69-bridgewater');
GO

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'star-trail-prosper'
      AND source_url = 'https://startrailprosper.com/'
      AND builder_name = 'Highland Homes'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('star-trail-prosper', 'highland-homes',
 'https://startrailprosper.com/',
 'firecrawl', NULL, NULL,
 'raw', 'web_page_det', 'page', 1, 'Files/web/star-trail-prosper/',
 1, 'Star Trail Parkway / Star Trail Prosper community site',
 'Star Trail Parkway', 'Highland Homes');

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'star-trail-prosper'
      AND source_url = 'https://startrailprosper.com/'
      AND builder_name = 'Coventry Homes'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('star-trail-prosper', 'coventry-homes',
 'https://startrailprosper.com/',
 'firecrawl', NULL, NULL,
 'raw', 'web_page_det', 'page', 1, 'Files/web/star-trail-prosper/',
 1, 'Star Trail Prosper community site',
 'Star Trail', 'Coventry Homes');

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'star-trail-prosper'
      AND source_url = 'https://startrailprosper.com/'
      AND builder_name = 'American Legend Homes'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('star-trail-prosper', 'american-legend-homes',
 'https://startrailprosper.com/',
 'firecrawl', NULL, NULL,
 'raw', 'web_page_det', 'page', 1, 'Files/web/star-trail-prosper/',
 1, 'Star Trail Prosper community site',
 'Star Trail', 'American Legend Homes');

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'star-trail-prosper'
      AND source_url = 'https://startrailprosper.com/'
      AND builder_name = 'Britton Homes'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('star-trail-prosper', 'britton-homes',
 'https://startrailprosper.com/',
 'firecrawl', NULL, NULL,
 'raw', 'web_page_det', 'page', 1, 'Files/web/star-trail-prosper/',
 1, 'Star Trail Prosper community site',
 'Star Trail', 'Britton Homes');

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'star-trail-prosper'
      AND source_url = 'https://startrailprosper.com/'
      AND builder_name = 'Toll Brothers'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('star-trail-prosper', 'toll-brothers',
 'https://startrailprosper.com/',
 'firecrawl', NULL, NULL,
 'raw', 'web_page_det', 'page', 1, 'Files/web/star-trail-prosper/',
 1, 'Star Trail Prosper community site',
 'Star Trail', 'Toll Brothers');
GO

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'phillips-creek-ranch'
      AND source_url = 'https://www.phillipscreekranchtx.com/'
      AND builder_name = 'Highland Homes'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('phillips-creek-ranch', 'highland-homes',
 'https://www.phillipscreekranchtx.com/',
 'firecrawl', NULL, NULL,
 'raw', 'web_page_det', 'page', 1, 'Files/web/phillips-creek-ranch/',
 1, 'Phillips Creek Ranch community site',
 'Phillips Creek Ranch', 'Highland Homes');
GO

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'phillips-creek-ranch'
      AND source_url = 'https://www.phillipscreekranchtx.com/'
      AND builder_name = 'Huntington Homes'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('phillips-creek-ranch', 'huntington-homes',
 'https://www.phillipscreekranchtx.com/',
 'firecrawl', NULL, NULL,
 'raw', 'web_page_det', 'page', 1, 'Files/web/phillips-creek-ranch/',
 1, 'Phillips Creek Ranch community site',
 'Phillips Creek Ranch', 'Huntington Homes');
GO

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'phillips-creek-ranch'
      AND source_url = 'https://www.phillipscreekranchtx.com/'
      AND builder_name = 'Britton Homes'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('phillips-creek-ranch', 'britton-homes',
 'https://www.phillipscreekranchtx.com/',
 'firecrawl', NULL, NULL,
 'raw', 'web_page_det', 'page', 1, 'Files/web/phillips-creek-ranch/',
 1, 'Phillips Creek Ranch community site',
 'Phillips Creek Ranch', 'Britton Homes');
GO

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'phillips-creek-ranch'
      AND source_url = 'https://www.phillipscreekranchtx.com/'
      AND builder_name = 'Toll Brothers'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('phillips-creek-ranch', 'toll-brothers',
 'https://www.phillipscreekranchtx.com/',
 'firecrawl', NULL, NULL,
 'raw', 'web_page_det', 'page', 1, 'Files/web/phillips-creek-ranch/',
 1, 'Phillips Creek Ranch community site',
 'Phillips Creek Ranch', 'Toll Brothers');
GO

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'phillips-creek-ranch'
      AND source_url = 'https://www.phillipscreekranchtx.com/'
      AND builder_name = 'Drees Custom Homes'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('phillips-creek-ranch', 'drees-custom-homes',
 'https://www.phillipscreekranchtx.com/',
 'firecrawl', NULL, NULL,
 'raw', 'web_page_det', 'page', 1, 'Files/web/phillips-creek-ranch/',
 1, 'Phillips Creek Ranch community site',
 'Phillips Creek Ranch', 'Drees Custom Homes');
GO

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'phillips-creek-ranch'
      AND source_url = 'https://www.phillipscreekranchtx.com/'
      AND builder_name = 'Shaddock Homes'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('phillips-creek-ranch', 'shaddock-homes',
 'https://www.phillipscreekranchtx.com/',
 'firecrawl', NULL, NULL,
 'raw', 'web_page_det', 'page', 1, 'Files/web/phillips-creek-ranch/',
 1, 'Phillips Creek Ranch community site',
 'Phillips Creek Ranch', 'Shaddock Homes');
GO

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'phillips-creek-ranch'
      AND source_url = 'https://www.phillipscreekranchtx.com/'
      AND builder_name = 'Belclaire Homes'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('phillips-creek-ranch', 'belclaire-homes',
 'https://www.phillipscreekranchtx.com/',
 'firecrawl', NULL, NULL,
 'raw', 'web_page_det', 'page', 1, 'Files/web/phillips-creek-ranch/',
 1, 'Phillips Creek Ranch community site',
 'Phillips Creek Ranch', 'Belclaire Homes');
GO

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'phillips-creek-ranch'
      AND source_url = 'https://www.phillipscreekranchtx.com/'
      AND builder_name = 'Darling Homes'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('phillips-creek-ranch', 'darling-homes',
 'https://www.phillipscreekranchtx.com/',
 'firecrawl', NULL, NULL,
 'raw', 'web_page_det', 'page', 1, 'Files/web/phillips-creek-ranch/',
 1, 'Phillips Creek Ranch community site',
 'Phillips Creek Ranch', 'Darling Homes');
GO

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'phillips-creek-ranch'
      AND source_url = 'https://www.phillipscreekranchtx.com/'
      AND builder_name = 'MainVue Homes'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name)
VALUES
('phillips-creek-ranch', 'mainvue-homes',
 'https://www.phillipscreekranchtx.com/',
 'firecrawl', NULL, NULL,
 'raw', 'web_page_det', 'page', 1, 'Files/web/phillips-creek-ranch/',
 1, 'Phillips Creek Ranch community site',
 'Phillips Creek Ranch', 'MainVue Homes');
GO

EXEC control.sp_ensure_web_scrape_table 'raw', 'web_page_det', 'page';
EXEC control.sp_ensure_web_scrape_table 'raw', 'web_listing_det', 'listing';
EXEC control.sp_ensure_web_scrape_table 'raw', 'web_aggregator_det', 'listing';
GO

UPDATE control.web_scrape_source
SET scrape_mode = COALESCE(scrape_mode, table_shape)
WHERE scrape_mode IS NULL;
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'page',
    table_shape = 'page',
    target_schema = 'raw',
    target_table = 'web_page_det'
WHERE source_group = 'greenbrick-partners';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = COALESCE(listing_url, source_url)
WHERE source_group = 'perry-homes-bridgewater';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = 'https://www.highlandhomes.com/dfw/midlothian/bridgewater',
    wait_for_text = 'Quick Move-in',
    notes = 'Highland Homes BridgeWater Midlothian; QMI from homeSpec HTML, plans from availableIfps'
WHERE source_group = 'bridgewater-midlothian'
  AND source_name = 'highland-homes';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = 'https://www.tripointehomes.com/tx/dallas-fort-worth/discovery-collection-at-bridgewater',
    wait_for_text = 'Move-in Ready',
    notes = 'Tri Pointe Discovery Collection (50 ft); sitemap-homes plus JSON-LD Product. Hub URL kept without ad query string'
WHERE source_group = 'bridgewater-midlothian'
  AND source_name = 'tripointe-discovery';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = 'https://www.tripointehomes.com/tx/dallas-fort-worth/inspiration-collection-at-bridgewater',
    wait_for_text = 'Move-in Ready',
    notes = 'Tri Pointe Inspiration Collection (60 ft); sitemap-homes plus JSON-LD Product. Hub URL kept without ad query string'
WHERE source_group = 'bridgewater-midlothian'
  AND source_name = 'tripointe-inspiration';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = 'https://www.amlegendhomes.com/communities/texas/midlothian/bridgewater',
    wait_for_text = 'Quick Move-In',
    notes = 'American Legend Homes BridgeWater Midlothian; HomeCard QMI extract'
WHERE source_group = 'bridgewater-midlothian'
  AND source_name = 'american-legend-homes';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = 'https://jhoustonhomes.com/community/bridgewater/',
    wait_for_text = 'Available Now',
    notes = 'John Houston Homes Bridgewater Midlothian; jh-spec-card inventory and plans'
WHERE source_group = 'bridgewater-midlothian'
  AND source_name = 'john-houston-homes';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = 'https://cbjenihomes.com/communities/the-village-at-midtowne/',
    wait_for_text = 'Quick Move-in Homes',
    notes = 'CB JENI Homes The Village at Midtowne Midlothian; home-wrap QMI and floorplans. Hash #floorplans is an on-page anchor'
WHERE source_group = 'village-at-midtowne'
  AND source_name = 'cb-jeni-homes';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = 'https://www.highlandhomes.com/dfw/prosper/star-trail',
    wait_for_text = 'Quick Move-in',
    notes = 'Highland Homes builder community page for Star Trail'
WHERE source_group = 'star-trail-prosper'
  AND source_name = 'highland-homes';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = 'https://www.coventryhomes.com/new-homes/tx/prosper/star-trail/',
    wait_for_text = 'Move-In Ready',
    notes = 'Coventry Homes builder community page for Star Trail'
WHERE source_group = 'star-trail-prosper'
  AND source_name = 'coventry-homes';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = 'https://www.amlegendhomes.com/communities/texas/prosper/star-trail',
    wait_for_text = 'Available Now',
    notes = 'American Legend Homes builder community page for Star Trail'
WHERE source_group = 'star-trail-prosper'
  AND source_name = 'american-legend-homes';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = 'https://www.brittonhomestexas.com/new-homes/texas/dallas/star-trail/star-trail-76',
    wait_for_text = 'Sq. Ft.',
    notes = 'Britton Homes (Perry family) Star Trail 76 collection; JS rendered'
WHERE source_group = 'star-trail-prosper'
  AND source_name = 'britton-homes';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = 'https://www.tollbrothers.com/luxury-homes-for-sale/Texas/Star-Trail',
    wait_for_text = 'Quick Move-In',
    notes = 'Toll Brothers builder community page for Star Trail'
WHERE source_group = 'star-trail-prosper'
  AND source_name = 'toll-brothers';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = NULL,
    wait_for_text = NULL,
    notes = 'No live Highland PCR community page as of 2026-08-25; highlandhomes.com PCR path redirects to Frisco city (The Grove)'
WHERE source_group = 'phillips-creek-ranch'
  AND source_name = 'highland-homes';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = NULL,
    wait_for_text = NULL,
    notes = 'No live Huntington PCR listing page as of 2026-08-25; huntingtonhomestx.com/phillips-creek-ranch is an empty SPA shell'
WHERE source_group = 'phillips-creek-ranch'
  AND source_name = 'huntington-homes';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = NULL,
    wait_for_text = NULL,
    notes = 'No live Britton PCR listing page as of 2026-08-25; brittonhomestexas.com PCR path returns 404'
WHERE source_group = 'phillips-creek-ranch'
  AND source_name = 'britton-homes';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = NULL,
    wait_for_text = NULL,
    notes = 'No live Toll Brothers PCR community page as of 2026-08-25; path redirects to Texas-wide luxury homes'
WHERE source_group = 'phillips-creek-ranch'
  AND source_name = 'toll-brothers';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = NULL,
    wait_for_text = NULL,
    notes = 'No live Drees PCR community page as of 2026-08-25; path redirects to DFW homepage'
WHERE source_group = 'phillips-creek-ranch'
  AND source_name = 'drees-custom-homes';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = NULL,
    wait_for_text = NULL,
    notes = 'No PCR inventory page as of 2026-08-25; shaddockhomes.com/communities/phillips-creek-ranch is the DFW community index'
WHERE source_group = 'phillips-creek-ranch'
  AND source_name = 'shaddock-homes';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = NULL,
    wait_for_text = NULL,
    notes = 'No PCR inventory page as of 2026-08-25; belclairehomes.com/communities/phillips-creek-ranch is the DFW community index'
WHERE source_group = 'phillips-creek-ranch'
  AND source_name = 'belclaire-homes';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = 'https://www.taylormorrison.com/tx/dallas/frisco/phillips-creek-ranch',
    wait_for_text = 'SOLD OUT',
    notes = 'Darling Homes is now Taylor Morrison; PCR community page title SOLD OUT as of 2026-08-25'
WHERE source_group = 'phillips-creek-ranch'
  AND source_name = 'darling-homes';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = NULL,
    wait_for_text = NULL,
    notes = 'No live MainVue PCR page as of 2026-08-25; mainvuehomes.com TX path 404; MainVue currently lists Washington communities only'
WHERE source_group = 'phillips-creek-ranch'
  AND source_name = 'mainvue-homes';
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'raw'
      AND o.name = 'web_listing_det'
      AND c.name = 'source_group'
)
    ALTER TABLE raw.web_listing_det ADD source_group VARCHAR(64) NULL;
GO

UPDATE raw.web_listing_det
SET source_group = source_name
WHERE source_group IS NULL
  AND source_name IN (
      'perry-homes-bridgewater', 'star-trail-prosper', 'phillips-creek-ranch'
  );
GO

UPDATE raw.web_listing_det
SET source_group = 'star-trail-prosper'
WHERE source_group IS NULL
  AND source_name IN (
      'highland-homes', 'coventry-homes', 'american-legend-homes',
      'britton-homes', 'toll-brothers'
  )
  AND (
      community_name LIKE 'Star Trail%'
      OR community_name IS NULL
  );
GO

UPDATE raw.web_listing_det
SET source_group = 'phillips-creek-ranch'
WHERE source_group IS NULL
  AND source_name = 'darling-homes';
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_aggregator_det',
    scraper = 'apify_playwright',
    listing_url = 'https://jome.com/master-planned-community/tx/69-bridgewater',
    source_url = 'https://jome.com/master-planned-community/tx/69-bridgewater',
    wait_for_text = 'Available homes',
    community_name = 'BridgeWater',
    builder_name = 'Jome',
    files_prefix = 'Files/web/jome-bridgewater-midlothian/',
    notes = 'Jome BridgeWater Midlothian hub; secondary source only. Follows /community/tx/*bridgewater*midlothian* children. Never writes to web_listing_det. #builders is an on-page anchor.'
WHERE source_group = 'jome-bridgewater-midlothian'
  AND source_name = 'jome';
GO


IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'raw'
      AND o.name = 'web_listing_det'
      AND c.name = 'fill_source'
)
    ALTER TABLE raw.web_listing_det ADD fill_source VARCHAR(32) NULL;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'raw'
      AND o.name = 'web_listing_det'
      AND c.name = 'fill_ingest_date'
)
    ALTER TABLE raw.web_listing_det ADD fill_ingest_date DATE NULL;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'raw'
      AND o.name = 'web_aggregator_det'
      AND c.name = 'aggregator_name'
)
    ALTER TABLE raw.web_aggregator_det ADD aggregator_name VARCHAR(64) NULL;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'raw'
      AND o.name = 'web_aggregator_det'
      AND c.name = 'aggregator_url'
)
    ALTER TABLE raw.web_aggregator_det ADD aggregator_url VARCHAR(1000) NULL;
GO

/* ------------------------------------------------------------------
   Dataverse registry sync (read-only shortcuts on dataverse_gbpdev).
   Never writes to Enterprise Dataverse. Leaves registry_source=manual alone.
   ------------------------------------------------------------------ */

IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'control'
      AND o.name = 'web_scrape_source'
      AND c.name = 'registry_source'
)
    ALTER TABLE control.web_scrape_source ADD registry_source VARCHAR(32) NULL;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'control'
      AND o.name = 'web_scrape_source'
      AND c.name = 'community_id'
)
    ALTER TABLE control.web_scrape_source ADD community_id VARCHAR(64) NULL;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'control'
      AND o.name = 'web_scrape_source'
      AND c.name = 'brand_id'
)
    ALTER TABLE control.web_scrape_source ADD brand_id VARCHAR(64) NULL;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.columns c
    JOIN sys.objects o ON o.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = 'control'
      AND o.name = 'web_scrape_source'
      AND c.name = 'job_type'
)
    ALTER TABLE control.web_scrape_source ADD job_type VARCHAR(16) NULL;
GO

UPDATE control.web_scrape_source
SET registry_source = 'manual'
WHERE registry_source IS NULL;
GO

IF NOT EXISTS (
    SELECT 1 FROM control.web_scrape_source
    WHERE source_group = 'treeline-justin'
      AND source_name = 'pulte-listings'
      AND source_url = 'https://www.pulte.com/homes/texas/dallas/justin/treeline-211384'
)
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt, wait_for_text,
     target_schema, target_table, table_shape, create_table_if_missing, files_prefix,
     is_active, notes, community_name, builder_name, scrape_mode, listing_url,
     registry_source)
VALUES
('treeline-justin', 'pulte-listings',
 'https://www.pulte.com/homes/texas/dallas/justin/treeline-211384',
 'apify_playwright', NULL, 'Quick Move-In',
 'raw', 'web_listing_det', 'listing', 1, 'Files/web/treeline-justin/',
 1,
 'Pulte Treeline Justin TX; QMIGridCard HTML extract (browser UA required)',
 'Treeline', 'Pulte', 'listing',
 'https://www.pulte.com/homes/texas/dallas/justin/treeline-211384',
 'manual');
GO

UPDATE control.web_scrape_source
SET scrape_mode = 'listing',
    table_shape = 'listing',
    target_schema = 'raw',
    target_table = 'web_listing_det',
    scraper = 'apify_playwright',
    listing_url = 'https://www.pulte.com/homes/texas/dallas/justin/treeline-211384',
    source_url = 'https://www.pulte.com/homes/texas/dallas/justin/treeline-211384',
    wait_for_text = 'Quick Move-In',
    community_name = 'Treeline',
    builder_name = 'Pulte',
    files_prefix = 'Files/web/treeline-justin/',
    is_active = 1,
    registry_source = COALESCE(registry_source, 'manual'),
    notes = 'Pulte Treeline Justin TX; QMIGridCard HTML extract (browser UA required)'
WHERE source_group = 'treeline-justin'
  AND source_name = 'pulte-listings';
GO


IF OBJECT_ID('control.web_scrape_adapter') IS NULL
BEGIN
    CREATE TABLE control.web_scrape_adapter
    (
        host_name      VARCHAR(128)  NOT NULL,
        adapter        VARCHAR(64)   NOT NULL,
        wait_for_text  VARCHAR(128)  NULL,
        scraper        VARCHAR(32)   NOT NULL,
        notes          VARCHAR(512)  NULL,
        is_active      BIT           NOT NULL
    );
END
GO

IF EXISTS (
    SELECT 1
    FROM sys.key_constraints
    WHERE name = 'pk_web_scrape_adapter'
      AND parent_object_id = OBJECT_ID('control.web_scrape_adapter')
)
    ALTER TABLE control.web_scrape_adapter DROP CONSTRAINT pk_web_scrape_adapter;
GO

ALTER TABLE control.web_scrape_adapter
ADD CONSTRAINT pk_web_scrape_adapter
PRIMARY KEY NONCLUSTERED (host_name) NOT ENFORCED;
GO

MERGE control.web_scrape_adapter AS t
USING (VALUES
    ('highlandhomes.com', 'highland_cards', 'Quick Move-in', 'apify_playwright', 'Highland Homes community pages', 1),
    ('amlegendhomes.com', 'alh_homecard', 'Quick Move-In', 'apify_playwright', 'American Legend Homes', 1),
    ('tripointehomes.com', 'tripointe_jsonld', 'Move-in Ready', 'apify_playwright', 'Tri Pointe Homes', 1),
    ('perryhomes.com', 'perry_family', 'Sq. Ft.', 'apify_playwright', 'Perry Homes', 1),
    ('brittonhomestexas.com', 'perry_family', 'Sq. Ft.', 'apify_playwright', 'Britton Homes (Perry family)', 1),
    ('jhoustonhomes.com', 'jhouston_cards', 'Available Now', 'apify_playwright', 'John Houston Homes', 1),
    ('cbjenihomes.com', 'cbjeni_cards', 'Quick Move-in Homes', 'apify_playwright', 'CB JENI Homes', 1),
    ('coventryhomes.com', 'json_ld', 'Move-In Ready', 'apify_playwright', 'Coventry Homes', 1),
    ('tollbrothers.com', 'toll_next', 'Quick Move-In', 'apify_playwright', 'Toll Brothers', 1),
    ('taylormorrison.com', 'local_playwright_cards', 'Quick Move-In', 'local_playwright', 'Self-heal Playwright cards', 1),
    ('pulte.com', 'pulte_qmi', 'Quick Move-In', 'apify_playwright', 'Pulte Homes QMIGridCard HTML', 1),
    ('centex.com', 'pulte_qmi', 'Quick Move-In', 'apify_playwright', 'Centex (Pulte platform) QMIGridCard HTML', 1),
    ('jome.com', 'jome', 'Available homes', 'apify_playwright', 'Jome aggregator only (manual registry)', 1),
    ('ashtonwoods.com', 'local_playwright_ashtonwoods', 'Quick Move-In', 'local_playwright', 'property-card DOM via local Playwright', 1),
    ('lennar.com', 'local_playwright_cards', 'Quick Move-In', 'local_playwright', 'Self-heal Playwright cards', 1),
    ('mattamyhomes.com', 'local_playwright_cards', 'Quick Move-In', 'local_playwright', 'Self-heal Playwright cards', 1),
    ('mihomes.com', 'local_playwright_cards', 'Quick Move-In', 'local_playwright', 'Self-heal Playwright cards + detail enrich', 1),
    ('unionmainhomes.com', 'local_playwright_cards', 'Available', 'local_playwright', 'Self-heal Playwright cards', 1),
    ('traditionhomes.com', 'local_playwright_cards', 'Available', 'local_playwright', 'Self-heal Playwright cards', 1),
    ('drhorton.com', 'local_playwright_cards', 'Quick Move-In', 'local_playwright', 'Self-heal Playwright cards', 1),
    ('gfohome.com', 'local_playwright_cards', 'Available', 'local_playwright', 'Self-heal Playwright cards', 1),
    ('khov.com', 'local_playwright_cards', 'Available', 'local_playwright', 'Self-heal Playwright cards', 1),
    ('meritagehomes.com', 'local_playwright_cards', 'Homes for Sale', 'local_playwright',
     'Trophy competitor; Market Intelligence strategic heal', 1)
) AS s (host_name, adapter, wait_for_text, scraper, notes, is_active)
ON LOWER(t.host_name) = LOWER(s.host_name)
WHEN MATCHED THEN
    UPDATE SET
        adapter = s.adapter,
        wait_for_text = s.wait_for_text,
        scraper = s.scraper,
        notes = s.notes,
        is_active = s.is_active
WHEN NOT MATCHED THEN
    INSERT (host_name, adapter, wait_for_text, scraper, notes, is_active)
    VALUES (s.host_name, s.adapter, s.wait_for_text, s.scraper, s.notes, s.is_active);
GO

IF OBJECT_ID('control.web_scrape_run_det') IS NULL
BEGIN
    CREATE TABLE control.web_scrape_run_det
    (
        run_id              VARCHAR(36)    NOT NULL,
        ingest_date         DATE           NOT NULL,
        ingested_at         DATETIME2(0)   NOT NULL,
        flagged_communities INT            NULL,
        jobs_attempted      INT            NULL,
        jobs_skipped        INT            NULL,
        jobs_failed         INT            NULL,
        unknown_hosts       INT            NULL,
        rows_written        INT            NULL,
        summary_json        VARCHAR(MAX)   NULL
    );
END
GO

CREATE OR ALTER PROCEDURE control.sp_sync_web_scrape_from_dataverse
AS
BEGIN
    SET NOCOUNT ON;

    /* Read-only: dataverse_gbpdev shortcuts from Enterprise gbpdev.
       gbp_brands = competitor brand parent. Do not use gbp_builder. */

    ;WITH communities AS (
        SELECT
            c.gbp_communitiesid AS community_id,
            c.gbp_brand AS brand_id,
            LTRIM(RTRIM(c.gbp_name)) AS community_name,
            LTRIM(RTRIM(COALESCE(NULLIF(b.gbp_name, ''), c.gbp_brandname))) AS builder_name,
            LTRIM(RTRIM(c.gbp_listingsurl)) AS listings_url,
            LTRIM(RTRIM(c.gbp_plansurl)) AS plans_url,
            CAST(c.gbp_scanlistings AS INT) AS scan_listings,
            CAST(c.gbp_scanplans AS INT) AS scan_plans
        FROM dataverse_gbpdev.dbo.gbp_communities AS c
        LEFT JOIN dataverse_gbpdev.dbo.gbp_brands AS b
            ON b.gbp_brandsid = c.gbp_brand
           AND ISNULL(b.IsDelete, 0) = 0
        WHERE CAST(c.gbp_scanningallowed AS INT) = 1
          AND ISNULL(c.IsDelete, 0) = 0
          AND ISNULL(c.statecode, 0) = 0
    ),
    listing_jobs AS (
        SELECT
            community_id,
            brand_id,
            community_name,
            builder_name,
            listings_url AS job_url,
            CAST('listings' AS VARCHAR(16)) AS job_type
        FROM communities
        WHERE scan_listings = 1
          AND NULLIF(listings_url, '') IS NOT NULL
    ),
    plan_jobs AS (
        SELECT
            community_id,
            brand_id,
            community_name,
            builder_name,
            plans_url AS job_url,
            CAST('plans' AS VARCHAR(16)) AS job_type
        FROM communities
        WHERE scan_plans = 1
          AND NULLIF(plans_url, '') IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM listing_jobs AS l
              WHERE l.community_id = communities.community_id
                AND LOWER(l.job_url) = LOWER(plans_url)
          )
    ),
    jobs AS (
        SELECT * FROM listing_jobs
        UNION ALL
        SELECT * FROM plan_jobs
    ),
    staged AS (
        SELECT
            LEFT(
                LOWER(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        community_name, ' ', '-'), '''', ''), '"', ''),
                        '/', '-'), '#', ''), '.', '')
                ), 64
            ) AS source_group,
            LEFT(
                LOWER(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        COALESCE(NULLIF(builder_name, ''), 'brand'), ' ', '-'),
                        '''', ''), '"', ''), '/', '-'), '#', ''), '.', '')
                ) + '-' + job_type, 64
            ) AS source_name,
            job_url AS source_url,
            job_url AS listing_url,
            community_name,
            builder_name,
            community_id,
            brand_id,
            job_type,
            'Files/web/' + LEFT(
                LOWER(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        community_name, ' ', '-'), '''', ''), '"', ''),
                        '/', '-'), '#', ''), '.', '')
                ), 64
            ) + '/' AS files_prefix
        FROM jobs
    )
    MERGE control.web_scrape_source AS t
    USING staged AS s
        ON t.registry_source = 'dataverse'
       AND t.community_id = s.community_id
       AND t.job_type = s.job_type
    WHEN MATCHED THEN
        UPDATE SET
            source_group = s.source_group,
            source_name = s.source_name,
            source_url = s.source_url,
            listing_url = s.listing_url,
            community_name = s.community_name,
            builder_name = s.builder_name,
            brand_id = s.brand_id,
            files_prefix = s.files_prefix,
            scrape_mode = 'listing',
            table_shape = 'listing',
            target_schema = 'raw',
            target_table = 'web_listing_det',
            create_table_if_missing = 1,
            is_active = 1,
            notes = 'Synced from dataverse gbp_communities; adapter by host'
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            source_group, source_name, source_url, scraper, extract_prompt,
            wait_for_text, target_schema, target_table, table_shape,
            create_table_if_missing, files_prefix, is_active, notes,
            community_name, builder_name, scrape_mode, listing_url,
            registry_source, community_id, brand_id, job_type
        )
        VALUES (
            s.source_group, s.source_name, s.source_url, 'apify_playwright', NULL,
            NULL, 'raw', 'web_listing_det', 'listing',
            1, s.files_prefix, 1,
            'Synced from dataverse gbp_communities; adapter by host',
            s.community_name, s.builder_name, 'listing', s.listing_url,
            'dataverse', s.community_id, s.brand_id, s.job_type
        )
    WHEN NOT MATCHED BY SOURCE
        AND t.registry_source = 'dataverse'
    THEN
        UPDATE SET is_active = 0,
            notes = COALESCE(t.notes, '') + '; deactivated: no longer flagged in Dataverse';

    /* Hand-seeded rows that share a Dataverse listing URL become inactive.
       Manual-only rows (GBP homepage, Jome, wait_for overrides) stay. */
    UPDATE m
    SET
        m.is_active = 0,
        m.notes = COALESCE(m.notes, '') + '; deactivated: superseded by dataverse registry URL'
    FROM control.web_scrape_source AS m
    INNER JOIN control.web_scrape_source AS d
        ON d.registry_source = 'dataverse'
       AND d.is_active = 1
       AND LOWER(COALESCE(d.listing_url, d.source_url, ''))
           = LOWER(COALESCE(m.listing_url, m.source_url, ''))
    WHERE COALESCE(m.registry_source, 'manual') = 'manual'
      AND m.is_active = 1
      AND LOWER(COALESCE(m.target_table, '')) = 'web_listing_det'
      AND NULLIF(LOWER(COALESCE(m.listing_url, m.source_url, '')), '') IS NOT NULL;
END
GO

CREATE OR ALTER PROCEDURE control.sp_fill_web_listing_from_aggregator
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @agg_at DATETIME2(0) = (
        SELECT MAX(ingested_at)
        FROM raw.web_aggregator_det
        WHERE LOWER(COALESCE(aggregator_name, '')) = 'jome'
    );

    IF @agg_at IS NULL
        RETURN;

    UPDATE p
    SET
        p.price = CASE WHEN p.price IS NULL THEN a.price ELSE p.price END,
        p.starting_price = CASE WHEN p.starting_price IS NULL THEN a.starting_price ELSE p.starting_price END,
        p.square_feet = CASE WHEN p.square_feet IS NULL THEN a.square_feet ELSE p.square_feet END,
        p.bedrooms = CASE WHEN p.bedrooms IS NULL THEN a.bedrooms ELSE p.bedrooms END,
        p.bathrooms = CASE WHEN p.bathrooms IS NULL THEN a.bathrooms ELSE p.bathrooms END,
        p.address = CASE WHEN p.address IS NULL THEN a.address ELSE p.address END,
        p.plan_name = CASE WHEN p.plan_name IS NULL THEN a.plan_name ELSE p.plan_name END,
        p.plan_number = CASE WHEN p.plan_number IS NULL THEN a.plan_number ELSE p.plan_number END,
        p.elevation = CASE WHEN p.elevation IS NULL THEN a.elevation ELSE p.elevation END,
        p.stories = CASE WHEN p.stories IS NULL THEN a.stories ELSE p.stories END,
        p.garage_spaces = CASE WHEN p.garage_spaces IS NULL THEN a.garage_spaces ELSE p.garage_spaces END,
        p.lot_size = CASE WHEN p.lot_size IS NULL THEN a.lot_size ELSE p.lot_size END,
        p.availability_status = CASE WHEN p.availability_status IS NULL THEN a.availability_status ELSE p.availability_status END,
        p.estimated_move_in_date = CASE WHEN p.estimated_move_in_date IS NULL THEN a.estimated_move_in_date ELSE p.estimated_move_in_date END,
        p.listing_url = CASE WHEN p.listing_url IS NULL THEN a.listing_url ELSE p.listing_url END,
        p.plan_url = CASE WHEN p.plan_url IS NULL THEN a.plan_url ELSE p.plan_url END,
        p.fill_source = 'jome',
        p.fill_ingest_date = CAST(SYSUTCDATETIME() AS DATE)
    FROM raw.web_listing_det p
    INNER JOIN raw.web_aggregator_det a
        ON LOWER(COALESCE(a.aggregator_name, '')) = 'jome'
       AND a.ingested_at = @agg_at
       AND (
            CASE
                WHEN LOWER(COALESCE(a.builder_name, '')) LIKE '%american legend%' THEN 'american legend homes'
                WHEN LOWER(COALESCE(a.builder_name, '')) LIKE '%john houston%' THEN 'john houston homes'
                WHEN LOWER(COALESCE(a.builder_name, '')) LIKE '%highland%' THEN 'highland homes'
                WHEN LOWER(COALESCE(a.builder_name, '')) LIKE '%perry%' THEN 'perry homes'
                WHEN LOWER(COALESCE(a.builder_name, '')) LIKE '%tri%pointe%'
                  OR LOWER(COALESCE(a.builder_name, '')) LIKE '%tripointe%' THEN 'tri pointe homes'
                ELSE LOWER(LTRIM(RTRIM(COALESCE(a.builder_name, ''))))
            END
        ) = (
            CASE
                WHEN LOWER(COALESCE(p.builder_name, '')) LIKE '%american legend%' THEN 'american legend homes'
                WHEN LOWER(COALESCE(p.builder_name, '')) LIKE '%john houston%' THEN 'john houston homes'
                WHEN LOWER(COALESCE(p.builder_name, '')) LIKE '%highland%' THEN 'highland homes'
                WHEN LOWER(COALESCE(p.builder_name, '')) LIKE '%perry%' THEN 'perry homes'
                WHEN LOWER(COALESCE(p.builder_name, '')) LIKE '%tri%pointe%'
                  OR LOWER(COALESCE(p.builder_name, '')) LIKE '%tripointe%' THEN 'tri pointe homes'
                ELSE LOWER(LTRIM(RTRIM(COALESCE(p.builder_name, ''))))
            END
        )
       AND LOWER(COALESCE(p.community_name, '')) LIKE '%bridgewater%'
       AND (
            p.source_group = 'bridgewater-midlothian'
            OR LOWER(COALESCE(p.community_name, '')) LIKE '%midlothian%'
            OR LOWER(COALESCE(p.listing_url, '')) LIKE '%midlothian%'
       )
       AND LOWER(COALESCE(p.listing_url, '')) NOT LIKE '%/dallas/bridgewater%'
       AND (
            (
                LOWER(COALESCE(a.record_type, '')) = 'inventory'
                AND LOWER(COALESCE(p.record_type, '')) = 'inventory'
                AND REPLACE(REPLACE(REPLACE(REPLACE(
                        ' ' + UPPER(REPLACE(REPLACE(LTRIM(RTRIM(COALESCE(a.address, ''))), '.', ''), ',', '')) + ' ',
                        ' LN ', ' LANE '),
                        ' TRL ', ' TRAIL '),
                        ' DR ', ' DRIVE '),
                        ' CT ', ' COURT ')
                    = REPLACE(REPLACE(REPLACE(REPLACE(
                        ' ' + UPPER(REPLACE(REPLACE(LTRIM(RTRIM(COALESCE(p.address, ''))), '.', ''), ',', '')) + ' ',
                        ' LN ', ' LANE '),
                        ' TRL ', ' TRAIL '),
                        ' DR ', ' DRIVE '),
                        ' CT ', ' COURT ')
                AND LEN(LTRIM(RTRIM(COALESCE(a.address, '')))) > 0
            )
            OR (
                LOWER(COALESCE(a.record_type, '')) = 'plan'
                AND LOWER(COALESCE(p.record_type, '')) = 'plan'
                AND (
                    (
                        NULLIF(LTRIM(RTRIM(a.plan_number)), '') IS NOT NULL
                        AND NULLIF(LTRIM(RTRIM(p.plan_number)), '') IS NOT NULL
                        AND LTRIM(RTRIM(a.plan_number)) = LTRIM(RTRIM(p.plan_number))
                    )
                    OR (
                        (
                            NULLIF(LTRIM(RTRIM(a.plan_number)), '') IS NULL
                            OR NULLIF(LTRIM(RTRIM(p.plan_number)), '') IS NULL
                        )
                        AND LEN(LTRIM(RTRIM(COALESCE(a.plan_name, '')))) > 0
                        AND UPPER(LTRIM(RTRIM(a.plan_name))) = UPPER(LTRIM(RTRIM(p.plan_name)))
                    )
                )
            )
       )
    WHERE
        (p.price IS NULL AND a.price IS NOT NULL)
        OR (p.starting_price IS NULL AND a.starting_price IS NOT NULL)
        OR (p.square_feet IS NULL AND a.square_feet IS NOT NULL)
        OR (p.bedrooms IS NULL AND a.bedrooms IS NOT NULL)
        OR (p.bathrooms IS NULL AND a.bathrooms IS NOT NULL)
        OR (p.address IS NULL AND a.address IS NOT NULL)
        OR (p.plan_name IS NULL AND a.plan_name IS NOT NULL)
        OR (p.plan_number IS NULL AND a.plan_number IS NOT NULL)
        OR (p.elevation IS NULL AND a.elevation IS NOT NULL)
        OR (p.stories IS NULL AND a.stories IS NOT NULL)
        OR (p.garage_spaces IS NULL AND a.garage_spaces IS NOT NULL)
        OR (p.lot_size IS NULL AND a.lot_size IS NOT NULL)
        OR (p.availability_status IS NULL AND a.availability_status IS NOT NULL)
        OR (p.estimated_move_in_date IS NULL AND a.estimated_move_in_date IS NOT NULL)
        OR (p.listing_url IS NULL AND a.listing_url IS NOT NULL)
        OR (p.plan_url IS NULL AND a.plan_url IS NOT NULL);

    INSERT INTO raw.web_listing_det (
        builder_name, community_name, record_type, plan_name, elevation,
        plan_number, price, starting_price, square_feet, bedrooms, bathrooms,
        stories, garage_spaces, lot_size, address, availability_status,
        estimated_move_in_date, listing_url, plan_url, run_id, ingest_date,
        ingested_at, scraper, source_name, source_group, fill_source,
        fill_ingest_date
    )
    SELECT
        a.builder_name,
        COALESCE(NULLIF(LTRIM(RTRIM(a.community_name)), ''), 'BridgeWater'),
        a.record_type,
        a.plan_name,
        a.elevation,
        a.plan_number,
        a.price,
        a.starting_price,
        a.square_feet,
        a.bedrooms,
        a.bathrooms,
        a.stories,
        a.garage_spaces,
        a.lot_size,
        a.address,
        a.availability_status,
        a.estimated_move_in_date,
        a.listing_url,
        a.plan_url,
        CONVERT(VARCHAR(36), NEWID()),
        CAST(SYSUTCDATETIME() AS DATE),
        SYSUTCDATETIME(),
        'aggregator_fill',
        CASE
            WHEN LOWER(COALESCE(a.builder_name, '')) LIKE '%american legend%' THEN 'american-legend-homes'
            WHEN LOWER(COALESCE(a.builder_name, '')) LIKE '%john houston%' THEN 'john-houston-homes'
            WHEN LOWER(COALESCE(a.builder_name, '')) LIKE '%highland%' THEN 'highland-homes'
            WHEN LOWER(COALESCE(a.builder_name, '')) LIKE '%perry%' THEN 'perry'
            WHEN LOWER(COALESCE(a.builder_name, '')) LIKE '%tri%pointe%'
              OR LOWER(COALESCE(a.builder_name, '')) LIKE '%tripointe%' THEN 'tripointe'
            ELSE 'jome-fill'
        END,
        CASE
            WHEN LOWER(COALESCE(a.builder_name, '')) LIKE '%perry%' THEN 'perry-homes-bridgewater'
            ELSE 'bridgewater-midlothian'
        END,
        'jome',
        CAST(SYSUTCDATETIME() AS DATE)
    FROM raw.web_aggregator_det a
    WHERE LOWER(COALESCE(a.aggregator_name, '')) = 'jome'
      AND a.ingested_at = @agg_at
      AND (
            LOWER(COALESCE(a.record_type, '')) = 'inventory'
            AND LEN(LTRIM(RTRIM(COALESCE(a.address, '')))) > 0
         OR LOWER(COALESCE(a.record_type, '')) = 'plan'
            AND (
                LEN(LTRIM(RTRIM(COALESCE(a.plan_number, '')))) > 0
                OR LEN(LTRIM(RTRIM(COALESCE(a.plan_name, '')))) > 0
            )
      )
      AND NOT EXISTS (
          SELECT 1
          FROM raw.web_listing_det p
          WHERE (
                    CASE
                        WHEN LOWER(COALESCE(a.builder_name, '')) LIKE '%american legend%' THEN 'american legend homes'
                        WHEN LOWER(COALESCE(a.builder_name, '')) LIKE '%john houston%' THEN 'john houston homes'
                        WHEN LOWER(COALESCE(a.builder_name, '')) LIKE '%highland%' THEN 'highland homes'
                        WHEN LOWER(COALESCE(a.builder_name, '')) LIKE '%perry%' THEN 'perry homes'
                        WHEN LOWER(COALESCE(a.builder_name, '')) LIKE '%tri%pointe%'
                          OR LOWER(COALESCE(a.builder_name, '')) LIKE '%tripointe%' THEN 'tri pointe homes'
                        ELSE LOWER(LTRIM(RTRIM(COALESCE(a.builder_name, ''))))
                    END
                ) = (
                    CASE
                        WHEN LOWER(COALESCE(p.builder_name, '')) LIKE '%american legend%' THEN 'american legend homes'
                        WHEN LOWER(COALESCE(p.builder_name, '')) LIKE '%john houston%' THEN 'john houston homes'
                        WHEN LOWER(COALESCE(p.builder_name, '')) LIKE '%highland%' THEN 'highland homes'
                        WHEN LOWER(COALESCE(p.builder_name, '')) LIKE '%perry%' THEN 'perry homes'
                        WHEN LOWER(COALESCE(p.builder_name, '')) LIKE '%tri%pointe%'
                          OR LOWER(COALESCE(p.builder_name, '')) LIKE '%tripointe%' THEN 'tri pointe homes'
                        ELSE LOWER(LTRIM(RTRIM(COALESCE(p.builder_name, ''))))
                    END
                )
            AND LOWER(COALESCE(p.community_name, '')) LIKE '%bridgewater%'
            AND (
                p.source_group = 'bridgewater-midlothian'
                OR LOWER(COALESCE(p.community_name, '')) LIKE '%midlothian%'
                OR LOWER(COALESCE(p.listing_url, '')) LIKE '%midlothian%'
            )
            AND LOWER(COALESCE(p.listing_url, '')) NOT LIKE '%/dallas/bridgewater%'
            AND (
                (
                    LOWER(COALESCE(a.record_type, '')) = 'inventory'
                    AND LOWER(COALESCE(p.record_type, '')) = 'inventory'
                    AND REPLACE(REPLACE(REPLACE(REPLACE(
                            ' ' + UPPER(REPLACE(REPLACE(LTRIM(RTRIM(COALESCE(a.address, ''))), '.', ''), ',', '')) + ' ',
                            ' LN ', ' LANE '),
                            ' TRL ', ' TRAIL '),
                            ' DR ', ' DRIVE '),
                            ' CT ', ' COURT ')
                        = REPLACE(REPLACE(REPLACE(REPLACE(
                            ' ' + UPPER(REPLACE(REPLACE(LTRIM(RTRIM(COALESCE(p.address, ''))), '.', ''), ',', '')) + ' ',
                            ' LN ', ' LANE '),
                            ' TRL ', ' TRAIL '),
                            ' DR ', ' DRIVE '),
                            ' CT ', ' COURT ')
                    AND LEN(LTRIM(RTRIM(COALESCE(a.address, '')))) > 0
                )
                OR (
                    LOWER(COALESCE(a.record_type, '')) = 'plan'
                    AND LOWER(COALESCE(p.record_type, '')) = 'plan'
                    AND (
                        (
                            NULLIF(LTRIM(RTRIM(a.plan_number)), '') IS NOT NULL
                            AND NULLIF(LTRIM(RTRIM(p.plan_number)), '') IS NOT NULL
                            AND LTRIM(RTRIM(a.plan_number)) = LTRIM(RTRIM(p.plan_number))
                        )
                        OR (
                            (
                                NULLIF(LTRIM(RTRIM(a.plan_number)), '') IS NULL
                                OR NULLIF(LTRIM(RTRIM(p.plan_number)), '') IS NULL
                            )
                            AND LEN(LTRIM(RTRIM(COALESCE(a.plan_name, '')))) > 0
                            AND UPPER(LTRIM(RTRIM(a.plan_name))) = UPPER(LTRIM(RTRIM(p.plan_name)))
                        )
                    )
                )
            )
      );
END
GO
