-- VOC sentiment codes must be in controlled vocabulary when present.
SELECT *
FROM {{ ref('customer_survey_comment_det') }}
WHERE sentiment_code IS NOT NULL
  AND sentiment_code NOT IN ('POSITIVE', 'NEGATIVE', 'NEUTRAL', 'MIXED')
