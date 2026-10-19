{{ config(materialized='view', schema='analytics', alias='customer_survey_theme_det') }}

/*
  One row per comment x theme assignment.
  Grain: source_comment_id x theme_code.
*/

WITH base AS (
    SELECT
        source_comment_id,
        primary_theme_code,
        secondary_theme_codes,
        confidence_score,
        taxonomy_version,
        classified_at_utc
    FROM {{ ref('customer_survey_comment_det') }}
    WHERE is_comment_eligible = 1
),

primary_rows AS (
    SELECT
        source_comment_id,
        primary_theme_code AS theme_code,
        CAST(1 AS BIT) AS is_primary_theme,
        confidence_score,
        taxonomy_version,
        classified_at_utc
    FROM base
    WHERE primary_theme_code IS NOT NULL
),

secondary_rows AS (
    SELECT
        b.source_comment_id,
        LTRIM(RTRIM(value)) AS theme_code,
        CAST(0 AS BIT) AS is_primary_theme,
        b.confidence_score,
        b.taxonomy_version,
        b.classified_at_utc
    FROM base AS b
    CROSS APPLY STRING_SPLIT(COALESCE(b.secondary_theme_codes, ''), ',') AS ss
    WHERE LTRIM(RTRIM(ss.value)) <> ''
      AND LTRIM(RTRIM(ss.value)) <> COALESCE(b.primary_theme_code, '')
)

SELECT
    CONCAT(source_comment_id, '|', theme_code) AS theme_assignment_id,
    source_comment_id,
    theme_code,
    is_primary_theme,
    confidence_score,
    taxonomy_version,
    classified_at_utc,
    SYSUTCDATETIME() AS calculated_at_utc
FROM primary_rows
UNION ALL
SELECT
    CONCAT(source_comment_id, '|', theme_code) AS theme_assignment_id,
    source_comment_id,
    theme_code,
    is_primary_theme,
    confidence_score,
    taxonomy_version,
    classified_at_utc,
    SYSUTCDATETIME() AS calculated_at_utc
FROM secondary_rows
