-- Fail when peer_group_type is null while peer benchmarks are present.
SELECT *
FROM {{ ref('customer_survey_statistical_sum') }}
WHERE peer_mean_score IS NOT NULL
  AND peer_group_type IS NULL
