/*
  control.customer_survey_voc_config
  VOC pipeline configuration, run audit, exceptions, and notebook stage table.
  Target: warehouse_stage (Foundation Development). Never dbo.
*/

IF OBJECT_ID('control.customer_survey_voc_config') IS NULL
BEGIN
    CREATE TABLE control.customer_survey_voc_config
    (
        config_version              INT             NOT NULL,
        effective_start_date        DATE            NOT NULL,
        effective_end_date          DATE            NULL,
        is_active                   BIT             NOT NULL,
        ai_provider                 VARCHAR(32)     NOT NULL,
        model_version               VARCHAR(64)     NOT NULL,
        taxonomy_version            INT             NOT NULL,
        batch_size                  INT             NOT NULL,
        max_retries                 INT             NOT NULL,
        retry_delay_seconds         INT             NOT NULL,
        min_confidence_threshold    DECIMAL(5, 4)   NOT NULL,
        conflict_rating_threshold   DECIMAL(5, 4)   NOT NULL,
        journey_stage_method        VARCHAR(32)     NOT NULL,
        key_vault_url               VARCHAR(256)    NULL,
        secret_name                 VARCHAR(128)    NULL,
        enable_pii_redaction        BIT             NOT NULL,
        notes                       VARCHAR(512)    NULL
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'pk_customer_survey_voc_config'
      AND parent_object_id = OBJECT_ID('control.customer_survey_voc_config')
)
    ALTER TABLE control.customer_survey_voc_config
    ADD CONSTRAINT pk_customer_survey_voc_config
    PRIMARY KEY NONCLUSTERED (config_version) NOT ENFORCED;
GO

MERGE control.customer_survey_voc_config AS t
USING (VALUES
    (1, CAST('2026-01-01' AS DATE), NULL, 1,
     'KEYWORD_RULES', 'keyword-rules-v2', 1, 50, 3, 30,
     0.6000, 0.4000, 'RULES_FIRST',
     'https://gb-fabric-keyvault.vault.azure.net/', 'custsat-voc-api-key',
     1, 'Wave 0 approved keyword rules v2. Fabric AI not wired. Schedule OFF.')
) AS s (
    config_version, effective_start_date, effective_end_date, is_active,
    ai_provider, model_version, taxonomy_version, batch_size,
    max_retries, retry_delay_seconds, min_confidence_threshold,
    conflict_rating_threshold, journey_stage_method,
    key_vault_url, secret_name, enable_pii_redaction, notes
)
ON t.config_version = s.config_version
WHEN MATCHED THEN UPDATE SET
    effective_start_date = s.effective_start_date,
    effective_end_date = s.effective_end_date,
    is_active = s.is_active,
    ai_provider = s.ai_provider,
    model_version = s.model_version,
    taxonomy_version = s.taxonomy_version,
    batch_size = s.batch_size,
    max_retries = s.max_retries,
    retry_delay_seconds = s.retry_delay_seconds,
    min_confidence_threshold = s.min_confidence_threshold,
    conflict_rating_threshold = s.conflict_rating_threshold,
    journey_stage_method = s.journey_stage_method,
    key_vault_url = s.key_vault_url,
    secret_name = s.secret_name,
    enable_pii_redaction = s.enable_pii_redaction,
    notes = s.notes
WHEN NOT MATCHED THEN INSERT (
    config_version, effective_start_date, effective_end_date, is_active,
    ai_provider, model_version, taxonomy_version, batch_size,
    max_retries, retry_delay_seconds, min_confidence_threshold,
    conflict_rating_threshold, journey_stage_method,
    key_vault_url, secret_name, enable_pii_redaction, notes
)
VALUES (
    s.config_version, s.effective_start_date, s.effective_end_date, s.is_active,
    s.ai_provider, s.model_version, s.taxonomy_version, s.batch_size,
    s.max_retries, s.retry_delay_seconds, s.min_confidence_threshold,
    s.conflict_rating_threshold, s.journey_stage_method,
    s.key_vault_url, s.secret_name, s.enable_pii_redaction, s.notes
);
GO

IF OBJECT_ID('control.customer_survey_voc_run_det') IS NULL
BEGIN
    CREATE TABLE control.customer_survey_voc_run_det
    (
        run_id                      VARCHAR(36)     NOT NULL,
        started_at_utc              DATETIME2(0)    NOT NULL,
        completed_at_utc            DATETIME2(0)    NULL,
        run_status                  VARCHAR(32)     NOT NULL,
        ai_provider                 VARCHAR(32)     NOT NULL,
        model_version               VARCHAR(64)     NOT NULL,
        taxonomy_version            INT             NOT NULL,
        eligible_comment_count      INT             NOT NULL,
        processed_count             INT             NOT NULL,
        skipped_unchanged_count     INT             NOT NULL,
        success_count               INT             NOT NULL,
        failure_count               INT             NOT NULL,
        pii_detected_count          INT             NOT NULL,
        human_review_count          INT             NOT NULL,
        error_summary               VARCHAR(1000)   NULL
    );
END
GO

IF OBJECT_ID('control.customer_survey_voc_exception_det') IS NULL
BEGIN
    CREATE TABLE control.customer_survey_voc_exception_det
    (
        exception_id                VARCHAR(36)     NOT NULL,
        run_id                      VARCHAR(36)     NOT NULL,
        source_comment_id           VARCHAR(64)     NOT NULL,
        exception_at_utc            DATETIME2(0)    NOT NULL,
        exception_type              VARCHAR(64)     NOT NULL,
        exception_reason            VARCHAR(1000)   NOT NULL,
        retry_count                 INT             NOT NULL,
        raw_response_excerpt        VARCHAR(512)    NULL
    );
END
GO

IF OBJECT_ID('analytics.customer_survey_voc_comment_stage') IS NULL
BEGIN
    CREATE TABLE analytics.customer_survey_voc_comment_stage
    (
        source_comment_id           VARCHAR(64)     NOT NULL,
        response_id                 VARCHAR(64)     NOT NULL,
        normalized_comment_hash     VARCHAR(64)     NOT NULL,
        redacted_response_text      VARCHAR(MAX)    NULL,
        pii_detected_flag           BIT             NOT NULL,
        is_comment_eligible         BIT             NOT NULL,
        comment_ineligibility_reason VARCHAR(128)   NULL,
        journey_stage               VARCHAR(64)     NULL,
        sentiment_code              VARCHAR(32)     NULL,
        urgency_code                VARCHAR(32)     NULL,
        action_code                 VARCHAR(32)     NULL,
        primary_theme_code          VARCHAR(64)     NULL,
        secondary_theme_codes       VARCHAR(512)    NULL,
        confidence_score            DECIMAL(5, 4)   NULL,
        human_review_required       BIT             NOT NULL,
        rating_sentiment_conflict   BIT             NOT NULL,
        ai_provider                 VARCHAR(32)     NOT NULL,
        model_version               VARCHAR(64)     NOT NULL,
        taxonomy_version            INT             NOT NULL,
        classified_at_utc             DATETIME2(0)    NOT NULL,
        classification_json         VARCHAR(MAX)    NULL
    );
END
GO

UPDATE analytics.customer_survey_voc_comment_stage
SET ai_provider = 'KEYWORD_RULES',
    model_version = 'keyword-rules-v1'
WHERE ai_provider IN ('MOCK', 'FABRIC_AI');
GO

UPDATE control.customer_survey_voc_run_det
SET ai_provider = 'KEYWORD_RULES',
    model_version = 'keyword-rules-v1'
WHERE ai_provider IN ('MOCK', 'FABRIC_AI');
GO
