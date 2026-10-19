{{ config(materialized='view', schema='analytics', alias='customer_survey_comment_det') }}

/*
  Enriched text comments for VOC. No buyer PII in output columns.
  Grain: one row per eligible text response.
*/

SELECT
    COALESCE(s.source_comment_id, o.response_id) AS source_comment_id,
    o.response_id,
    o.survey_response_id,
    o.question_id,
    o.question_name,
    o.question_category,
    o.survey_name,
    o.survey_completed_on,
    o.operating_unit_code,
    o.operating_unit_label,
    o.project_id,
    o.project_code,
    o.project_name,
    s.normalized_comment_hash,
    s.redacted_response_text,
    s.pii_detected_flag,
    COALESCE(s.is_comment_eligible, 0) AS is_comment_eligible,
    s.comment_ineligibility_reason,
    COALESCE(s.journey_stage, o.survey_name) AS journey_stage,
    s.sentiment_code,
    s.urgency_code,
    s.action_code,
    s.primary_theme_code,
    s.secondary_theme_codes,
    s.confidence_score,
    COALESCE(s.human_review_required, 0) AS human_review_required,
    COALESCE(s.rating_sentiment_conflict, 0) AS rating_sentiment_conflict,
    COALESCE(s.ai_provider, 'NONE') AS ai_provider,
    COALESCE(s.model_version, 'NONE') AS model_version,
    COALESCE(s.taxonomy_version, 1) AS taxonomy_version,
    s.classified_at_utc,
    SYSUTCDATETIME() AS calculated_at_utc
FROM {{ ref('customer_survey_obt') }} AS o
LEFT JOIN {{ source('analytics', 'customer_survey_voc_comment_stage') }} AS s
    ON o.response_id = s.response_id
WHERE o.question_type_name = 'Text'
