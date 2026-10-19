-- Suppressed rows must not be classified as rankable alerts.
SELECT *
FROM {{ ref('customer_survey_statistical_sum') }}
WHERE minimum_sample_status = 'SUPPRESSED'
  AND classification IN ('ALERT', 'WARNING')
