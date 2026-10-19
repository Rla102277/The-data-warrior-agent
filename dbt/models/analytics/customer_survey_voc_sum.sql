{{ config(materialized='view', schema='analytics', alias='customer_survey_voc_sum') }}

/*
  Aggregated VOC metrics. No PII.
  Grain: operating unit x project x survey x period x theme.
*/

SELECT
    c.operating_unit_code,
    c.operating_unit_label,
    c.project_id,
    c.project_code,
    c.project_name,
    c.survey_name,
    DATEFROMPARTS(YEAR(c.survey_completed_on), MONTH(c.survey_completed_on), 1)
        AS period_start_date,
    COALESCE(t.theme_code, c.primary_theme_code, 'OTHER') AS theme_code,
    COUNT(*) AS comment_count,
    SUM(CASE WHEN c.sentiment_code = 'POSITIVE' THEN 1 ELSE 0 END) AS positive_count,
    SUM(CASE WHEN c.sentiment_code = 'NEGATIVE' THEN 1 ELSE 0 END) AS negative_count,
    SUM(CASE WHEN c.sentiment_code = 'NEUTRAL' THEN 1 ELSE 0 END) AS neutral_count,
    SUM(CASE WHEN c.sentiment_code = 'MIXED' THEN 1 ELSE 0 END) AS mixed_count,
    SUM(CASE WHEN c.action_code = 'ACTION_REQUIRED' THEN 1 ELSE 0 END) AS action_required_count,
    SUM(CASE WHEN c.urgency_code IN ('HIGH', 'CRITICAL') THEN 1 ELSE 0 END) AS high_urgency_count,
    SUM(CASE WHEN c.human_review_required = 1 THEN 1 ELSE 0 END) AS human_review_count,
    AVG(c.confidence_score) AS avg_confidence_score,
    CASE
        WHEN COUNT(*) = 0 THEN NULL
        ELSE
            CAST(SUM(CASE WHEN c.sentiment_code = 'POSITIVE' THEN 1 ELSE 0 END) AS FLOAT)
            / NULLIF(CAST(COUNT(*) AS FLOAT), 0)
            - CAST(SUM(CASE WHEN c.sentiment_code = 'NEGATIVE' THEN 1 ELSE 0 END) AS FLOAT)
            / NULLIF(CAST(COUNT(*) AS FLOAT), 0)
    END AS net_sentiment_ratio,
    SYSUTCDATETIME() AS calculated_at_utc
FROM {{ ref('customer_survey_comment_det') }} AS c
LEFT JOIN {{ ref('customer_survey_theme_det') }} AS t
    ON c.source_comment_id = t.source_comment_id
   AND t.is_primary_theme = 1
WHERE c.is_comment_eligible = 1
GROUP BY
    c.operating_unit_code,
    c.operating_unit_label,
    c.project_id,
    c.project_code,
    c.project_name,
    c.survey_name,
    DATEFROMPARTS(YEAR(c.survey_completed_on), MONTH(c.survey_completed_on), 1),
    COALESCE(t.theme_code, c.primary_theme_code, 'OTHER')
