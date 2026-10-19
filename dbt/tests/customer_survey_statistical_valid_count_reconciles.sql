-- Valid rating rows must reconcile to statistical response layer.
WITH rated AS (
    SELECT COUNT(*) AS rated_n
    FROM {{ ref('customer_survey_response_statistical_det') }}
    WHERE is_valid_rating = 1
),
agg AS (
    SELECT SUM(response_count) AS agg_n
    FROM {{ ref('customer_survey_statistical_sum') }}
    WHERE entity_type = 'PROJECT'
)
SELECT *
FROM rated
CROSS JOIN agg
WHERE rated.rated_n <> agg.agg_n
