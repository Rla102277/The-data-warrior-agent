/*
  control.customer_survey_voc_review
  Human review write-back for VOC classifications.
  Original classification_json on analytics.customer_survey_voc_comment_stage is never deleted.
  Status: CONFIRMED | OVERRIDE | DISMISSED (PENDING = no row / not reviewed yet).

  Target: warehouse_stage. Never dbo. Foundation Development only.
*/

IF OBJECT_ID('control.customer_survey_voc_review') IS NULL
BEGIN
    CREATE TABLE control.customer_survey_voc_review
    (
        source_comment_id               VARCHAR(64)     NOT NULL,
        review_status                   VARCHAR(32)     NOT NULL,
        reviewer_upn                    VARCHAR(128)    NULL,
        reviewed_at_utc                 DATETIME2(0)    NOT NULL,
        override_sentiment_code         VARCHAR(32)     NULL,
        override_urgency_code           VARCHAR(32)     NULL,
        override_action_code            VARCHAR(32)     NULL,
        override_primary_theme_code     VARCHAR(64)     NULL,
        review_notes                    VARCHAR(1000)   NULL
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'pk_customer_survey_voc_review'
      AND parent_object_id = OBJECT_ID('control.customer_survey_voc_review')
)
    ALTER TABLE control.customer_survey_voc_review
    ADD CONSTRAINT pk_customer_survey_voc_review
    PRIMARY KEY NONCLUSTERED (source_comment_id) NOT ENFORCED;
GO
