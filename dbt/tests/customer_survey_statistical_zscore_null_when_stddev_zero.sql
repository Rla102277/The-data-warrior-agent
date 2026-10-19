-- Z-score must be null when peer stddev is zero.
SELECT *
FROM {{ ref('customer_survey_statistical_sum') }}
WHERE peer_stddev_score = 0
  AND z_score IS NOT NULL
