-- Each question should map to a single active scale row per version.
SELECT
    question_id,
    map_version,
    COUNT(*) AS scale_rows
FROM {{ source('control', 'customer_survey_question_scale_map') }}
WHERE is_active = 1
GROUP BY question_id, map_version
HAVING COUNT(*) > 1
