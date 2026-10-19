{{ config(materialized='view', schema='analytics', alias='customer_survey_statistical_sum') }}

/*
  Aggregated statistical metrics with peer benchmarks.
  Grain: entity x peer_group_type x period x question dimensions.
*/

WITH active_config AS (
    SELECT TOP 1
        minimum_sample_size,
        confidence_level,
        z_score_warning_threshold,
        z_score_alert_threshold,
        enable_stabilized_score,
        stabilized_prior_weight
    FROM {{ source('control', 'customer_survey_statistical_config') }}
    WHERE is_active = 1
      AND CAST(GETUTCDATE() AS DATE)
          BETWEEN effective_start_date AND COALESCE(effective_end_date, CAST('9999-12-31' AS DATE))
    ORDER BY config_version DESC
),

rated AS (
    SELECT
        r.*,
        DATEFROMPARTS(YEAR(r.survey_completed_on), MONTH(r.survey_completed_on), 1)
            AS period_start_date,
        EOMONTH(r.survey_completed_on) AS period_end_date
    FROM {{ ref('customer_survey_response_statistical_det') }} AS r
    WHERE r.is_valid_rating = 1
      AND r.normalized_score IS NOT NULL
      AND r.survey_completed_on IS NOT NULL
),

project_metrics AS (
    SELECT
        CAST('PROJECT' AS VARCHAR(32)) AS entity_type,
        CAST(project_id AS VARCHAR(64)) AS entity_id,
        MAX(project_name) AS entity_name,
        operating_unit_code,
        question_id,
        MAX(question_name) AS question_name,
        MAX(question_category) AS question_category,
        survey_name,
        period_start_date,
        MAX(period_end_date) AS period_end_date,
        COUNT(*) AS response_count,
        AVG(normalized_score) AS mean_score,
        STDEV(normalized_score) AS stddev_score,
        MIN(normalized_score) AS min_score,
        MAX(normalized_score) AS max_score
    FROM rated
    WHERE project_id IS NOT NULL
    GROUP BY
        project_id,
        operating_unit_code,
        question_id,
        survey_name,
        period_start_date
),

ou_peer AS (
    SELECT
        operating_unit_code,
        question_id,
        survey_name,
        period_start_date,
        AVG(normalized_score) AS peer_mean_score,
        STDEV(normalized_score) AS peer_stddev_score,
        COUNT(*) AS peer_response_count
    FROM rated
    WHERE operating_unit_code IS NOT NULL
    GROUP BY operating_unit_code, question_id, survey_name, period_start_date
),

enterprise_peer AS (
    SELECT
        question_id,
        survey_name,
        period_start_date,
        AVG(normalized_score) AS peer_mean_score,
        STDEV(normalized_score) AS peer_stddev_score,
        COUNT(*) AS peer_response_count
    FROM rated
    GROUP BY question_id, survey_name, period_start_date
),

project_vs_ou AS (
    SELECT
        e.entity_type,
        e.entity_id,
        e.entity_name,
        e.operating_unit_code,
        e.question_id,
        e.question_name,
        e.question_category,
        e.survey_name,
        e.period_start_date,
        e.period_end_date,
        CAST('PROJECT_VS_OPERATING_UNIT' AS VARCHAR(64)) AS peer_group_type,
        e.response_count,
        e.mean_score,
        CAST(NULL AS FLOAT) AS median_score,
        e.stddev_score,
        e.min_score,
        e.max_score,
        p.peer_mean_score,
        p.peer_stddev_score,
        p.peer_response_count,
        CASE
            WHEN e.stddev_score IS NULL OR e.stddev_score = 0 THEN NULL
            WHEN e.response_count < c.minimum_sample_size THEN NULL
            ELSE (e.mean_score - p.peer_mean_score) / NULLIF(p.peer_stddev_score, 0)
        END AS z_score,
        CASE
            WHEN e.response_count >= c.minimum_sample_size THEN 'MET'
            ELSE 'SUPPRESSED'
        END AS minimum_sample_status,
        CASE
            WHEN e.stddev_score IS NULL OR e.stddev_score = 0 THEN 'INSUFFICIENT_VARIANCE'
            WHEN e.response_count < c.minimum_sample_size THEN 'INSUFFICIENT_SAMPLE'
            WHEN ABS((e.mean_score - p.peer_mean_score) / NULLIF(p.peer_stddev_score, 0))
                >= c.z_score_alert_threshold THEN 'ALERT'
            WHEN ABS((e.mean_score - p.peer_mean_score) / NULLIF(p.peer_stddev_score, 0))
                >= c.z_score_warning_threshold THEN 'WARNING'
            ELSE 'NORMAL'
        END AS classification,
        e.mean_score AS raw_mean_score,
        CASE
            WHEN c.enable_stabilized_score = 1 AND p.peer_response_count > 0 THEN
                (e.mean_score * e.response_count
                    + p.peer_mean_score * c.stabilized_prior_weight)
                / NULLIF(e.response_count + c.stabilized_prior_weight, 0)
            ELSE e.mean_score
        END AS stabilized_mean_score,
        CASE
            WHEN e.response_count < c.minimum_sample_size THEN NULL
            ELSE e.mean_score - 1.96 * e.stddev_score / NULLIF(SQRT(CAST(e.response_count AS FLOAT)), 0)
        END AS ci_lower_bound,
        CASE
            WHEN e.response_count < c.minimum_sample_size THEN NULL
            ELSE e.mean_score + 1.96 * e.stddev_score / NULLIF(SQRT(CAST(e.response_count AS FLOAT)), 0)
        END AS ci_upper_bound,
        SYSUTCDATETIME() AS calculated_at_utc
    FROM project_metrics AS e
    CROSS JOIN active_config AS c
    LEFT JOIN ou_peer AS p
        ON e.operating_unit_code = p.operating_unit_code
       AND e.question_id = p.question_id
       AND e.survey_name = p.survey_name
       AND e.period_start_date = p.period_start_date
),

ou_vs_enterprise AS (
    SELECT
        CAST('OPERATING_UNIT' AS VARCHAR(32)) AS entity_type,
        CAST(r.operating_unit_code AS VARCHAR(64)) AS entity_id,
        CAST(MAX(r.operating_unit_name) AS VARCHAR(256)) AS entity_name,
        r.operating_unit_code,
        r.question_id,
        MAX(r.question_name) AS question_name,
        MAX(r.question_category) AS question_category,
        r.survey_name,
        r.period_start_date,
        MAX(r.period_end_date) AS period_end_date,
        CAST('OPERATING_UNIT_VS_ENTERPRISE' AS VARCHAR(64)) AS peer_group_type,
        COUNT(*) AS response_count,
        AVG(r.normalized_score) AS mean_score,
        CAST(NULL AS FLOAT) AS median_score,
        STDEV(r.normalized_score) AS stddev_score,
        MIN(r.normalized_score) AS min_score,
        MAX(r.normalized_score) AS max_score,
        ep.peer_mean_score,
        ep.peer_stddev_score,
        ep.peer_response_count,
        CASE
            WHEN STDEV(r.normalized_score) IS NULL OR STDEV(r.normalized_score) = 0 THEN NULL
            WHEN COUNT(*) < c.minimum_sample_size THEN NULL
            ELSE (AVG(r.normalized_score) - ep.peer_mean_score) / NULLIF(ep.peer_stddev_score, 0)
        END AS z_score,
        CASE
            WHEN COUNT(*) >= c.minimum_sample_size THEN 'MET'
            ELSE 'SUPPRESSED'
        END AS minimum_sample_status,
        CASE
            WHEN STDEV(r.normalized_score) IS NULL OR STDEV(r.normalized_score) = 0 THEN 'INSUFFICIENT_VARIANCE'
            WHEN COUNT(*) < c.minimum_sample_size THEN 'INSUFFICIENT_SAMPLE'
            WHEN ABS((AVG(r.normalized_score) - ep.peer_mean_score) / NULLIF(ep.peer_stddev_score, 0))
                >= c.z_score_alert_threshold THEN 'ALERT'
            WHEN ABS((AVG(r.normalized_score) - ep.peer_mean_score) / NULLIF(ep.peer_stddev_score, 0))
                >= c.z_score_warning_threshold THEN 'WARNING'
            ELSE 'NORMAL'
        END AS classification,
        AVG(r.normalized_score) AS raw_mean_score,
        AVG(r.normalized_score) AS stabilized_mean_score,
        CASE
            WHEN COUNT(*) < c.minimum_sample_size THEN NULL
            ELSE AVG(r.normalized_score)
                - 1.96 * STDEV(r.normalized_score) / NULLIF(SQRT(CAST(COUNT(*) AS FLOAT)), 0)
        END AS ci_lower_bound,
        CASE
            WHEN COUNT(*) < c.minimum_sample_size THEN NULL
            ELSE AVG(r.normalized_score)
                + 1.96 * STDEV(r.normalized_score) / NULLIF(SQRT(CAST(COUNT(*) AS FLOAT)), 0)
        END AS ci_upper_bound,
        SYSUTCDATETIME() AS calculated_at_utc
    FROM rated AS r
    CROSS JOIN active_config AS c
    LEFT JOIN enterprise_peer AS ep
        ON r.question_id = ep.question_id
       AND r.survey_name = ep.survey_name
       AND r.period_start_date = ep.period_start_date
    WHERE r.operating_unit_code IS NOT NULL
    GROUP BY
        r.operating_unit_code,
        r.question_id,
        r.survey_name,
        r.period_start_date,
        ep.peer_mean_score,
        ep.peer_stddev_score,
        ep.peer_response_count,
        c.minimum_sample_size,
        c.z_score_alert_threshold,
        c.z_score_warning_threshold
)

SELECT * FROM project_vs_ou
UNION ALL
SELECT * FROM ou_vs_enterprise
