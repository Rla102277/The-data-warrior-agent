/*
  control.customer_survey_theme_map
  VOC theme taxonomy (versioned).
  Target: warehouse_stage (Foundation Development). Never dbo.
*/

IF OBJECT_ID('control.customer_survey_theme_map') IS NULL
BEGIN
    CREATE TABLE control.customer_survey_theme_map
    (
        theme_code            VARCHAR(64)    NOT NULL,
        theme_name            VARCHAR(128)   NOT NULL,
        theme_category        VARCHAR(64)    NOT NULL,
        theme_description     VARCHAR(512)   NULL,
        taxonomy_version      INT            NOT NULL,
        effective_start_date  DATE           NOT NULL,
        effective_end_date    DATE           NULL,
        is_active             BIT            NOT NULL,
        sort_order            INT            NOT NULL,
        notes                 VARCHAR(512)   NULL
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'pk_customer_survey_theme_map'
      AND parent_object_id = OBJECT_ID('control.customer_survey_theme_map')
)
    ALTER TABLE control.customer_survey_theme_map
    ADD CONSTRAINT pk_customer_survey_theme_map
    PRIMARY KEY NONCLUSTERED (theme_code, taxonomy_version) NOT ENFORCED;
GO

MERGE control.customer_survey_theme_map AS t
USING (VALUES
    ('SALES_EXPERIENCE', 'Sales experience', 'JOURNEY', 'Sales process, contract, pricing clarity', 1, '2026-01-01', NULL, 1, 10, NULL),
    ('DESIGN_SELECTION', 'Design and selections', 'JOURNEY', 'Design center, options, upgrades', 1, '2026-01-01', NULL, 1, 20, NULL),
    ('CONSTRUCTION_QUALITY', 'Construction quality', 'JOURNEY', 'Build quality, craftsmanship, punch items', 1, '2026-01-01', NULL, 1, 30, NULL),
    ('SCHEDULE_COMMUNICATION', 'Schedule and communication', 'JOURNEY', 'Timeline updates, responsiveness', 1, '2026-01-01', NULL, 1, 40, NULL),
    ('CLOSING_TITLE', 'Closing and title', 'JOURNEY', 'Closing, title, paperwork', 1, '2026-01-01', NULL, 1, 50, NULL),
    ('ORIENTATION_MOVEIN', 'Orientation and move-in', 'JOURNEY', 'Orientation, move-in, warranty start', 1, '2026-01-01', NULL, 1, 60, NULL),
    ('WARRANTY_SERVICE', 'Warranty and service', 'JOURNEY', 'Post-close warranty and repairs', 1, '2026-01-01', NULL, 1, 70, NULL),
    ('COMMUNITY_AMENITY', 'Community and amenities', 'JOURNEY', 'Neighborhood, amenities, HOA', 1, '2026-01-01', NULL, 1, 80, NULL),
    ('LENDER_MORTGAGE', 'Lender and mortgage', 'JOURNEY', 'Mortgage partner experience', 1, '2026-01-01', NULL, 1, 90, NULL),
    ('OVERALL_SATISFACTION', 'Overall satisfaction', 'SUMMARY', 'General praise or dissatisfaction', 1, '2026-01-01', NULL, 1, 100, NULL),
    ('OTHER', 'Other', 'SUMMARY', 'Does not fit primary taxonomy', 1, '2026-01-01', NULL, 1, 999, NULL)
) AS s (
    theme_code, theme_name, theme_category, theme_description,
    taxonomy_version, effective_start_date, effective_end_date,
    is_active, sort_order, notes
)
ON t.theme_code = s.theme_code AND t.taxonomy_version = s.taxonomy_version
WHEN MATCHED THEN UPDATE SET
    theme_name = s.theme_name,
    theme_category = s.theme_category,
    theme_description = s.theme_description,
    effective_start_date = s.effective_start_date,
    effective_end_date = s.effective_end_date,
    is_active = s.is_active,
    sort_order = s.sort_order,
    notes = s.notes
WHEN NOT MATCHED THEN INSERT (
    theme_code, theme_name, theme_category, theme_description,
    taxonomy_version, effective_start_date, effective_end_date,
    is_active, sort_order, notes
)
VALUES (
    s.theme_code, s.theme_name, s.theme_category, s.theme_description,
    s.taxonomy_version, s.effective_start_date, s.effective_end_date,
    s.is_active, s.sort_order, s.notes
);
GO
