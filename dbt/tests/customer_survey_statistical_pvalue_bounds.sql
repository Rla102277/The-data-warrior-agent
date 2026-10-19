-- Two-sided p-values and BH-FDR adjusted p-values stay in [0, 1].
SELECT *
FROM {{ ref('customer_survey_statistical_det') }}
WHERE (p_value IS NOT NULL AND (p_value < 0 OR p_value > 1))
   OR (adjusted_p_value IS NOT NULL AND (adjusted_p_value < 0 OR adjusted_p_value > 1))
   OR (p_value IS NULL AND adjusted_p_value IS NOT NULL)
   OR (p_value IS NOT NULL AND test_statistic IS NULL)
   OR (test_statistic IS NOT NULL AND p_value IS NULL)
