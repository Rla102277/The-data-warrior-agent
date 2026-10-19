-- CI bounds must be ordered when both are present.
SELECT *
FROM {{ ref('customer_survey_statistical_sum') }}
WHERE ci_lower_bound IS NOT NULL
  AND ci_upper_bound IS NOT NULL
  AND ci_lower_bound > ci_upper_bound
