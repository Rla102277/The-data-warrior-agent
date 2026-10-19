/*
  control.customer_survey_statistical_config
  Versioned statistical thresholds for CustSat intelligence.
  Target: warehouse_stage (Foundation Development). Never dbo.
*/

IF OBJECT_ID('control.customer_survey_statistical_config') IS NULL
BEGIN
    CREATE TABLE control.customer_survey_statistical_config
    (
        config_version              INT             NOT NULL,
        effective_start_date        DATE            NOT NULL,
        effective_end_date          DATE            NULL,
        is_active                   BIT             NOT NULL,
        minimum_sample_size         INT             NOT NULL,
        confidence_level            DECIMAL(5, 4)   NOT NULL,
        alpha                       DECIMAL(5, 4)   NOT NULL,
        z_score_warning_threshold   DECIMAL(8, 4)   NOT NULL,
        z_score_alert_threshold     DECIMAL(8, 4)   NOT NULL,
        multiple_comparison_method  VARCHAR(32)     NOT NULL,
        practical_change_threshold  DECIMAL(8, 4)   NOT NULL,
        enable_stabilized_score     BIT             NOT NULL,
        stabilized_prior_weight     DECIMAL(8, 4)   NOT NULL,
        notes                       VARCHAR(512)    NULL
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'pk_customer_survey_statistical_config'
      AND parent_object_id = OBJECT_ID('control.customer_survey_statistical_config')
)
    ALTER TABLE control.customer_survey_statistical_config
    ADD CONSTRAINT pk_customer_survey_statistical_config
    PRIMARY KEY NONCLUSTERED (config_version) NOT ENFORCED;
GO

MERGE control.customer_survey_statistical_config AS t
USING (VALUES
    (1, CAST('2026-01-01' AS DATE), NULL, 1,
     30, 0.9500, 0.0500, 1.0000, 2.0000, 'BH-FDR', 0.0500, 0, 0.2500,
     'Wave 0 approved n=30 as the CLT floor for the 95% CI and z-score. Signed 2026-09-03.')
) AS s (
    config_version, effective_start_date, effective_end_date, is_active,
    minimum_sample_size, confidence_level, alpha,
    z_score_warning_threshold, z_score_alert_threshold,
    multiple_comparison_method, practical_change_threshold,
    enable_stabilized_score, stabilized_prior_weight, notes
)
ON t.config_version = s.config_version
WHEN MATCHED THEN UPDATE SET
    effective_start_date = s.effective_start_date,
    effective_end_date = s.effective_end_date,
    is_active = s.is_active,
    minimum_sample_size = s.minimum_sample_size,
    confidence_level = s.confidence_level,
    alpha = s.alpha,
    z_score_warning_threshold = s.z_score_warning_threshold,
    z_score_alert_threshold = s.z_score_alert_threshold,
    multiple_comparison_method = s.multiple_comparison_method,
    practical_change_threshold = s.practical_change_threshold,
    enable_stabilized_score = s.enable_stabilized_score,
    stabilized_prior_weight = s.stabilized_prior_weight,
    notes = s.notes
WHEN NOT MATCHED THEN INSERT (
    config_version, effective_start_date, effective_end_date, is_active,
    minimum_sample_size, confidence_level, alpha,
    z_score_warning_threshold, z_score_alert_threshold,
    multiple_comparison_method, practical_change_threshold,
    enable_stabilized_score, stabilized_prior_weight, notes
)
VALUES (
    s.config_version, s.effective_start_date, s.effective_end_date, s.is_active,
    s.minimum_sample_size, s.confidence_level, s.alpha,
    s.z_score_warning_threshold, s.z_score_alert_threshold,
    s.multiple_comparison_method, s.practical_change_threshold,
    s.enable_stabilized_score, s.stabilized_prior_weight, s.notes
);
GO
