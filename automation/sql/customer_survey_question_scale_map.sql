/*
  control.customer_survey_question_scale_map
  Per-question rating scale bounds. Refresh from FD discovery query.
  Target: warehouse_stage (Foundation Development). Never dbo.
*/

IF OBJECT_ID('control.customer_survey_question_scale_map') IS NULL
BEGIN
    CREATE TABLE control.customer_survey_question_scale_map
    (
        question_id           VARCHAR(64)    NOT NULL,
        question_name         VARCHAR(256)   NULL,
        question_category     VARCHAR(128)   NULL,
        scale_minimum         DECIMAL(8, 2)  NOT NULL,
        scale_maximum         DECIMAL(8, 2)  NOT NULL,
        is_reverse_scored     BIT            NOT NULL,
        scale_status          VARCHAR(32)    NOT NULL,
        map_version           INT            NOT NULL,
        effective_start_date  DATE           NOT NULL,
        effective_end_date    DATE           NULL,
        is_active             BIT            NOT NULL,
        notes                 VARCHAR(512)   NULL
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.key_constraints
    WHERE name = 'pk_customer_survey_question_scale_map'
      AND parent_object_id = OBJECT_ID('control.customer_survey_question_scale_map')
)
    ALTER TABLE control.customer_survey_question_scale_map
    ADD CONSTRAINT pk_customer_survey_question_scale_map
    PRIMARY KEY NONCLUSTERED (question_id, map_version) NOT ENFORCED;
GO

/*
  Approved Wave 0 (2026-09-03): wire 0-10 for all Rating questions.
  Discovery file: knowledge/operations/customer-survey-scale-discovery.md
*/
IF OBJECT_ID('analytics.customer_survey_obt', 'V') IS NOT NULL
BEGIN
    MERGE control.customer_survey_question_scale_map AS t
    USING (
        SELECT DISTINCT
            CAST(question_id AS VARCHAR(64)) AS question_id,
            CAST(question_name AS VARCHAR(256)) AS question_name,
            CAST(question_category AS VARCHAR(128)) AS question_category,
            CAST(0 AS DECIMAL(8, 2)) AS scale_minimum,
            CAST(10 AS DECIMAL(8, 2)) AS scale_maximum,
            CAST(0 AS BIT) AS is_reverse_scored,
            CAST('APPROVED' AS VARCHAR(32)) AS scale_status,
            CAST(1 AS INT) AS map_version,
            CAST('2026-01-01' AS DATE) AS effective_start_date,
            CAST(NULL AS DATE) AS effective_end_date,
            CAST(1 AS BIT) AS is_active,
            CAST('Wave 0 approved 0-10 forward score. Signed 2026-09-03.' AS VARCHAR(512)) AS notes
        FROM analytics.customer_survey_obt
        WHERE question_type_name = 'Rating'
          AND question_id IS NOT NULL
    ) AS s
    ON t.question_id = s.question_id AND t.map_version = s.map_version
    WHEN MATCHED THEN UPDATE SET
        question_name = s.question_name,
        question_category = s.question_category,
        scale_minimum = s.scale_minimum,
        scale_maximum = s.scale_maximum,
        is_reverse_scored = s.is_reverse_scored,
        scale_status = s.scale_status,
        is_active = s.is_active,
        notes = s.notes
    WHEN NOT MATCHED THEN INSERT (
        question_id, question_name, question_category,
        scale_minimum, scale_maximum, is_reverse_scored, scale_status,
        map_version, effective_start_date, effective_end_date, is_active, notes
    )
    VALUES (
        s.question_id, s.question_name, s.question_category,
        s.scale_minimum, s.scale_maximum, s.is_reverse_scored, s.scale_status,
        s.map_version, s.effective_start_date, s.effective_end_date, s.is_active, s.notes
    );
END
GO
