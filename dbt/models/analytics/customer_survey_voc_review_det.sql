{{ config(materialized='view', schema='analytics', alias='customer_survey_voc_review_det') }}

/*
  Human review queue for VOC classifications.
  Grain: one row per comment requiring review.
  Queue rule (Wave 0): human_review_required (NEGATIVE keywords) or rating-sentiment conflict.
  Do not use confidence_score < 0.60 alone; keyword confidence is a constant 0.55.
  review_status comes from control.customer_survey_voc_review write-back (default PENDING).
  Original stage classification_json is never overwritten by this view.
*/

SELECT
    c.source_comment_id,
    c.response_id,
    c.survey_completed_on,
    c.operating_unit_code,
    c.project_name,
    c.survey_name,
    c.journey_stage,
    c.redacted_response_text,
    c.sentiment_code,
    c.urgency_code,
    c.action_code,
    c.primary_theme_code,
    c.confidence_score,
    c.rating_sentiment_conflict,
    CASE
        WHEN c.rating_sentiment_conflict = 1 THEN 'RATING_SENTIMENT_CONFLICT'
        WHEN c.human_review_required = 1 THEN 'NEGATIVE_KEYWORD'
        WHEN c.primary_theme_code IS NULL THEN 'MISSING_THEME'
        ELSE 'MANUAL_REVIEW'
    END AS review_reason_code,
    CAST(COALESCE(r.review_status, 'PENDING') AS VARCHAR(32)) AS review_status,
    r.reviewer_upn,
    r.reviewed_at_utc,
    r.override_sentiment_code,
    r.override_urgency_code,
    r.override_action_code,
    r.override_primary_theme_code,
    r.review_notes,
    c.ai_provider,
    c.model_version,
    c.taxonomy_version,
    c.classified_at_utc,
    SYSUTCDATETIME() AS calculated_at_utc
FROM {{ ref('customer_survey_comment_det') }} AS c
LEFT JOIN {{ source('control', 'customer_survey_voc_review') }} AS r
    ON r.source_comment_id = c.source_comment_id
WHERE c.human_review_required = 1
   OR c.rating_sentiment_conflict = 1
