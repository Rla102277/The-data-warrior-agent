{{ config(materialized='view', schema='analytics', alias='customer_survey_response_statistical_det') }}

/*
  Enriched rating responses for statistical intelligence.
  Grain: response_id (inherits customer_survey_obt).
*/

WITH active_scale AS (
    SELECT
        question_id,
        scale_minimum,
        scale_maximum,
        is_reverse_scored,
        scale_status
    FROM {{ source('control', 'customer_survey_question_scale_map') }}
    WHERE is_active = 1
      AND CAST(GETUTCDATE() AS DATE)
          BETWEEN effective_start_date AND COALESCE(effective_end_date, CAST('9999-12-31' AS DATE))
),

base AS (
    SELECT
        o.*,
        s.scale_minimum,
        s.scale_maximum,
        s.is_reverse_scored,
        COALESCE(s.scale_status, 'UNKNOWN') AS scale_status
    FROM {{ ref('customer_survey_obt') }} AS o
    LEFT JOIN active_scale AS s
        ON o.question_id = s.question_id
)

SELECT
    response_id,
    survey_response_id,
    question_id,
    question_name,
    question_category,
    question_type_name,
    question_type_code,
    survey_name,
    survey_completed_on,
    operating_unit_code,
    operating_unit_name,
    operating_unit_label,
    project_id,
    project_code,
    project_name,
    sale_id,
    rating_value,
    response_text,
    scale_minimum,
    scale_maximum,
    is_reverse_scored,
    scale_status,
    CASE
        WHEN question_type_name <> 'Rating' THEN 0
        WHEN rating_value IS NULL THEN 0
        WHEN scale_minimum IS NULL OR scale_maximum IS NULL THEN 0
        WHEN rating_value < scale_minimum OR rating_value > scale_maximum THEN 0
        ELSE 1
    END AS is_valid_rating,
    CASE
        WHEN question_type_name = 'Rating' AND rating_value IS NULL THEN 1
        ELSE 0
    END AS is_missing_rating,
    CASE
        WHEN question_type_name <> 'Rating' OR rating_value IS NULL THEN NULL
        WHEN scale_maximum = scale_minimum THEN NULL
        WHEN is_reverse_scored = 1 THEN
            (scale_maximum - rating_value)
            / NULLIF(scale_maximum - scale_minimum, 0) * 100.0
        ELSE
            (rating_value - scale_minimum)
            / NULLIF(scale_maximum - scale_minimum, 0) * 100.0
    END AS normalized_score,
    CASE
        WHEN question_type_name = 'Text' THEN response_id
        ELSE NULL
    END AS source_comment_id,
    SYSUTCDATETIME() AS calculated_at_utc
FROM base
