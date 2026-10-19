/*
  control.analytics_refresh_config
  Drives pipeline_operations_analytics_refresh: materializes warehouse_stage
  analytics views (dbt project foundation) into lake_house_analytics
  for consumption (reports, semantic models) across Operations, Finance, Title, etc.

  domain column is ownership tag for filtering runs:
    operations | finance | title | shared
  model_class:
    entity = 1:1 current-row reference
    report = intentional report model (obt / det / sum / hist)
  Sink is lake_house_analytics.operations (one shared presentation lakehouse).

  Contract (2026-08-19):
    Entities are unsuffixed current-row tables. Do not publish *_active twins.
    Shapes: det = repeating line, obt = denormalized report row, sum = pre-agg
    (period suffix last), hist = snapshot/budget. pipeline_health_obt stays
    warehouse-only (utilities), not this lakehouse.
*/

IF OBJECT_ID('control.analytics_refresh_config') IS NOT NULL
    DROP TABLE control.analytics_refresh_config;

CREATE TABLE control.analytics_refresh_config
(
    domain          VARCHAR(32)   NOT NULL,
    target_name     VARCHAR(128)  NOT NULL,
    source_schema   VARCHAR(32)   NOT NULL,
    source_name     VARCHAR(128)  NOT NULL,
    is_active       BIT           NOT NULL,
    notes           VARCHAR(512)  NULL,
    model_class     VARCHAR(16)   NOT NULL
);

INSERT INTO control.analytics_refresh_config
    (domain, target_name, source_schema, source_name, is_active, notes, model_class)
VALUES
-- Shared / platform entities (current row)
('shared', 'calendar',                          'analytics', 'calendar',                          1, 'Gold vw_dim_date', 'entity'),
('shared', 'company',                           'analytics', 'company',                           1, 'Gold vw_dim_company; current row', 'entity'),
('shared', 'division',                          'analytics', 'division',                          1, 'Gold vw_dim_division; current row', 'entity'),
('shared', 'operating_unit',                    'analytics', 'operating_unit',                    1, 'Gold vw_dim_operating_unit; current row', 'entity'),
('shared', 'fiscal_period',                     'analytics', 'fiscal_period',                     1, 'Gold vw_dim_period; current row', 'entity'),
('shared', 'major_minor',                       'analytics', 'major_minor',                       1, 'Gold vw_dim_major_minor; current row', 'entity'),
('shared', 'plan',                              'analytics', 'plan',                              1, 'Gold vw_dim_plan_active promoted to plan', 'entity'),
('shared', 'project',                           'analytics', 'project',                           1, 'Gold vw_dim_project; current row', 'entity'),
('shared', 'lot',                               'analytics', 'lot',                               1, 'Gold vw_dim_lot; current row', 'entity'),
('shared', 'job',                               'analytics', 'job',                               1, 'Gold vw_dim_job; current row', 'entity'),
('shared', 'job_task',                          'analytics', 'job_task',                          1, 'Gold vw_dim_job_task; current row', 'entity'),
('shared', 'sale',                              'analytics', 'sale',                              1, 'Gold vw_dim_sale; current row', 'entity'),
('shared', 'sale_transfer',                     'analytics', 'sale_transfer',                     1, 'Gold vw_dim_sale_transfer', 'entity'),

-- Operations reporting
('operations', 'lot_events_obt',                'analytics', 'lot_events_obt',                    1, 'Gold vw_rep_lot_events; 1 row per lot-event', 'report'),
('operations', 'lot_obt',                       'analytics', 'lot_obt',                           1, '1 row per current lot + project + OU + sale + job', 'report'),
('operations', 'sale_obt',                      'analytics', 'sale_obt',                          1, 'Replaces misnamed sales_det; 1 row per current sale', 'report'),
('operations', 'lot_financials_obt',            'analytics', 'lot_financials_obt',                1, 'Wide SGM by lot; replaces lot_financials_sum publish', 'report'),
('operations', 'lot_financials_det',            'analytics', 'lot_financials_det',                1, 'Gold vw_fact_lot_financials; lot + SGM type', 'report'),
('operations', 'sales_sum_weekly',              'analytics', 'sales_sum_weekly',                  1, 'OU + week_start + event_type', 'report'),
('operations', 'unit_sum_weekly',               'analytics', 'unit_sum_weekly',                   1, 'OU + week_start; inventory on is_current_week only', 'report'),
('operations', 'sales_sum_monthly',             'analytics', 'sales_sum_monthly',                 1, 'OU + month_start + event_type; budget grain', 'report'),
('operations', 'customer_survey_obt',           'analytics', 'customer_survey_obt',               1, 'FD OBT rebuild; grain response_id', 'report'),
('operations', 'customer_survey_response_statistical_det', 'analytics', 'customer_survey_response_statistical_det', 1, 'CustSat rating enrichment; grain response_id', 'report'),
('operations', 'customer_survey_statistical_sum', 'analytics', 'customer_survey_statistical_sum', 1, 'CustSat statistical peer benchmarks', 'report'),
('operations', 'customer_survey_statistical_det', 'analytics', 'customer_survey_statistical_det', 1, 'CustSat period-over-period significance', 'report'),
('operations', 'customer_survey_comment_det',   'analytics', 'customer_survey_comment_det',       1, 'CustSat VOC enriched comments; grain source_comment_id', 'report'),
('operations', 'customer_survey_theme_det',     'analytics', 'customer_survey_theme_det',         1, 'CustSat VOC theme assignments', 'report'),
('operations', 'customer_survey_voc_sum',       'analytics', 'customer_survey_voc_sum',           1, 'CustSat VOC aggregated sentiment/themes', 'report'),
('operations', 'customer_survey_voc_review_det', 'analytics', 'customer_survey_voc_review_det',   1, 'CustSat VOC human review queue', 'report'),
('operations', 'web_listing_obt',               'analytics', 'web_listing_obt',                   1, 'Current web scrape snapshot; grain listing_key', 'report'),
('operations', 'web_community',                 'analytics', 'web_community',                     1, 'Zonda community analog from web scrape; grain community_key', 'entity'),
('operations', 'web_plan',                      'analytics', 'web_plan',                          1, 'Zonda plans analog from web scrape; grain plan_key', 'entity'),
('operations', 'web_lot',                       'analytics', 'web_lot',                           1, 'Zonda lots analog from web scrape; grain lot_key', 'entity'),
('operations', 'competitor_listing_obt',        'analytics', 'competitor_listing_obt',            1, 'Web + GBP ERP listings; grain listing_key; side competitor_web|gbp_web|gbp_erp', 'report'),
('operations', 'competitor_community_obt',      'analytics', 'competitor_community_obt',          1, 'Community + side competitor rollup; grain community_key + side', 'report'),
('operations', 'competitor_position_obt',       'analytics', 'competitor_position_obt',           1, 'Community x builder position; scanning peer + peer project + multi-builder competition', 'report'),
('operations', 'community_proximity_map',       'analytics', 'community_proximity_map',           1, 'GBP community proximity rings primary 3mi secondary 5mi enrichment', 'report'),
('operations', 'competitor_price_trend_obt',    'analytics', 'competitor_price_trend_obt',        1, 'Daily community x builder price/inventory trend from raw snapshots', 'report'),
('operations', 'competitor_peer_obt',           'analytics', 'competitor_peer_obt',               1, 'Named competitive peer sets (Trophy/MTH etc)', 'report'),
('operations', 'market_peer_community_obt',     'analytics', 'market_peer_community_obt',         1, 'Active Dataverse gbp_communities peers with scrape match', 'report'),
('operations', 'market_peer_project_obt',       'analytics', 'market_peer_project_obt',           1, 'Peer project links (gbp_gbppeercommunities) with project stamps + scrape match', 'report'),
('operations', 'market_dim_gbp_benchmark',      'analytics', 'market_dim_gbp_benchmark',          1, 'Selectable GBP benchmark communities for Peer Arena', 'entity'),
('operations', 'market_dim_peer_project',       'analytics', 'market_dim_peer_project',           1, 'Selectable peer project dim for Peer Arena', 'entity'),
('operations', 'market_dim_community',          'analytics', 'market_dim_community',              1, 'Shared community slicer dim for Market Intelligence', 'entity'),
('operations', 'market_dim_builder',            'analytics', 'market_dim_builder',                1, 'Shared builder slicer dim for Market Intelligence', 'entity'),
('operations', 'web_scrape_coverage_obt',       'analytics', 'web_scrape_coverage_obt',           1, 'Scrape coverage / freshness / completeness; grain source_group+source_name', 'report'),
('operations', 'web_listing_current',           'analytics', 'web_listing_current',               1, 'Current listing state + first/last/change timestamps', 'report'),
('operations', 'web_listing_change_det',        'analytics', 'web_listing_change_det',            1, 'Listing change events; added/price/status/attribute', 'report'),

-- Finance / SGM / GL
('finance', 'general_ledger_det',               'analytics', 'general_ledger_det',                1, 'Gold vw_fact_general_ledger', 'report'),
('finance', 'lot_sales_gross_margin_det',       'analytics', 'lot_sales_gross_margin_det',        1, 'Gold vw_fact_lot_sgm', 'report'),
('finance', 'sales_gross_margin_map',           'analytics', 'sales_gross_margin_map',            1, 'Gold vw_dim_sgm_map; current row', 'entity'),
('finance', 'sales_gross_margin_assumptions_det', 'analytics', 'sales_gross_margin_assumptions_det', 1, 'Full assumptions DET; replaces *_active publish', 'report'),
('finance', 'unit_budget_hist',                 'analytics', 'unit_budget_hist',                  1, 'From EDW_Silver.dbo.UnitBudgets2025 (not Gold)', 'report'),

-- Title
('title', 'title_booking_obt',                  'analytics', 'title_booking_obt',                 1, 'Gold vw_rep_title_booking; grain selection_id', 'report'),
('title', 'title_communities_det',              'analytics', 'title_communities_det',             1, 'Community map over title_booking_obt', 'report');
