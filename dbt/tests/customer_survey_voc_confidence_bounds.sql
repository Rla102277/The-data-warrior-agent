-- Confidence must be between 0 and 1 when present.
SELECT *
FROM {{ ref('customer_survey_comment_det') }}
WHERE confidence_score IS NOT NULL
  AND (confidence_score < 0 OR confidence_score > 1)
