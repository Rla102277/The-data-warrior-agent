{{ config(materialized='view', schema='analytics', alias='customer_survey_statistical_det') }}

/*
  Period-over-period significance detail for statistical intelligence.
  Grain: entity x peer_group_type x question x current vs prior period.

  p_value: two-sided standard normal tail of the Welch t statistic.
  Both sides are MET (n >= 30), so t is treated as z (Hastings AS 26.2.17).

  adjusted_p_value: BH-FDR within family
    question_id + survey_name + peer_group_type + current_period_start
  (all entities compared on the same question-month).
*/

WITH sums AS (
    SELECT *
    FROM {{ ref('customer_survey_statistical_sum') }}
    WHERE minimum_sample_status = 'MET'
),

paired AS (
    SELECT
        c.entity_type,
        c.entity_id,
        c.entity_name,
        c.operating_unit_code,
        c.question_id,
        c.question_name,
        c.question_category,
        c.survey_name,
        c.peer_group_type,
        c.period_start_date AS current_period_start,
        p.period_start_date AS prior_period_start,
        c.response_count AS current_response_count,
        p.response_count AS prior_response_count,
        c.mean_score AS current_mean_score,
        p.mean_score AS prior_mean_score,
        c.stddev_score AS current_stddev_score,
        p.stddev_score AS prior_stddev_score,
        c.z_score AS current_z_score,
        c.classification AS current_classification
    FROM sums AS c
    INNER JOIN sums AS p
        ON c.entity_type = p.entity_type
       AND c.entity_id = p.entity_id
       AND c.question_id = p.question_id
       AND c.survey_name = p.survey_name
       AND c.peer_group_type = p.peer_group_type
       AND p.period_start_date = DATEADD(MONTH, -1, c.period_start_date)
),

active_config AS (
    SELECT TOP 1
        alpha,
        practical_change_threshold
    FROM {{ source('control', 'customer_survey_statistical_config') }}
    WHERE is_active = 1
      AND CAST(GETUTCDATE() AS DATE)
          BETWEEN effective_start_date AND COALESCE(effective_end_date, CAST('9999-12-31' AS DATE))
    ORDER BY config_version DESC
),

scored AS (
    SELECT
        CONCAT(
            entity_type, '|', entity_id, '|', question_id, '|',
            survey_name, '|', peer_group_type, '|',
            CONVERT(VARCHAR(10), current_period_start, 120)
        ) AS comparison_id,
        entity_type,
        entity_id,
        entity_name,
        operating_unit_code,
        question_id,
        question_name,
        question_category,
        survey_name,
        peer_group_type,
        current_period_start,
        prior_period_start,
        current_response_count,
        prior_response_count,
        current_mean_score,
        prior_mean_score,
        current_mean_score - prior_mean_score AS mean_change,
        CAST('WELCH_T_TEST' AS VARCHAR(32)) AS comparison_method,
        CASE
            WHEN current_stddev_score IS NULL OR prior_stddev_score IS NULL THEN NULL
            WHEN current_response_count < 2 OR prior_response_count < 2 THEN NULL
            ELSE
                (current_mean_score - prior_mean_score)
                / NULLIF(
                    SQRT(
                        (POWER(current_stddev_score, 2) / NULLIF(CAST(current_response_count AS FLOAT), 0))
                        + (POWER(prior_stddev_score, 2) / NULLIF(CAST(prior_response_count AS FLOAT), 0))
                    ),
                    0
                )
        END AS test_statistic,
        CASE
            WHEN prior_mean_score IS NULL OR prior_mean_score = 0 THEN NULL
            ELSE (current_mean_score - prior_mean_score) / NULLIF(ABS(prior_mean_score), 0)
        END AS effect_size,
        CASE
            WHEN ABS(current_mean_score - prior_mean_score) >= cfg.practical_change_threshold THEN 1
            ELSE 0
        END AS practical_significance_flag,
        CASE
            WHEN current_response_count < 30 OR prior_response_count < 30 THEN 'INSUFFICIENT_SAMPLE'
            WHEN current_stddev_score IS NULL OR prior_stddev_score IS NULL THEN 'INSUFFICIENT_VARIANCE'
            ELSE 'COMPARED'
        END AS comparison_status_reason,
        cfg.alpha,
        cfg.practical_change_threshold
    FROM paired
    CROSS JOIN active_config AS cfg
),

with_z AS (
    SELECT
        s.*,
        CASE
            WHEN s.test_statistic IS NULL THEN NULL
            ELSE ABS(s.test_statistic)
        END AS z_abs
    FROM scored AS s
),

with_poly AS (
    SELECT
        z.*,
        CASE
            WHEN z.z_abs IS NULL THEN NULL
            ELSE 1.0 / (1.0 + 0.2316419 * z.z_abs)
        END AS t_poly
    FROM with_z AS z
),

with_p AS (
    SELECT
        p.*,
        CASE
            WHEN p.t_poly IS NULL THEN NULL
            WHEN 2.0 * (
                0.3989423 * EXP(-0.5 * POWER(p.z_abs, 2)) * p.t_poly * (
                    0.3193815
                    + p.t_poly * (
                        -0.3565638
                        + p.t_poly * (
                            1.781478
                            + p.t_poly * (-1.821256 + p.t_poly * 1.330274)
                        )
                    )
                )
            ) > 1.0 THEN 1.0
            ELSE 2.0 * (
                0.3989423 * EXP(-0.5 * POWER(p.z_abs, 2)) * p.t_poly * (
                    0.3193815
                    + p.t_poly * (
                        -0.3565638
                        + p.t_poly * (
                            1.781478
                            + p.t_poly * (-1.821256 + p.t_poly * 1.330274)
                        )
                    )
                )
            )
        END AS p_value
    FROM with_poly AS p
),

ranked AS (
    SELECT
        w.*,
        COUNT(w.p_value) OVER (
            PARTITION BY w.question_id, w.survey_name, w.peer_group_type, w.current_period_start
        ) AS fdr_family_size,
        CASE
            WHEN w.p_value IS NULL THEN NULL
            ELSE ROW_NUMBER() OVER (
                PARTITION BY
                    w.question_id,
                    w.survey_name,
                    w.peer_group_type,
                    w.current_period_start,
                    CASE WHEN w.p_value IS NULL THEN 1 ELSE 0 END
                ORDER BY w.p_value, w.comparison_id
            )
        END AS p_rank
    FROM with_p AS w
),

adjusted AS (
    SELECT
        r.*,
        CASE
            WHEN r.p_value IS NULL OR r.p_rank IS NULL OR r.fdr_family_size IS NULL THEN NULL
            ELSE r.p_value * CAST(r.fdr_family_size AS FLOAT) / NULLIF(CAST(r.p_rank AS FLOAT), 0)
        END AS adj_raw
    FROM ranked AS r
)

SELECT
    comparison_id,
    entity_type,
    entity_id,
    entity_name,
    operating_unit_code,
    question_id,
    question_name,
    question_category,
    survey_name,
    peer_group_type,
    current_period_start,
    prior_period_start,
    current_response_count,
    prior_response_count,
    current_mean_score,
    prior_mean_score,
    mean_change,
    comparison_method,
    test_statistic,
    p_value,
    CASE
        WHEN p_value IS NULL THEN NULL
        ELSE
            CASE
                WHEN MIN(CASE WHEN adj_raw > 1.0 THEN 1.0 ELSE adj_raw END) OVER (
                    PARTITION BY question_id, survey_name, peer_group_type, current_period_start
                    ORDER BY p_rank DESC
                    ROWS UNBOUNDED PRECEDING
                ) > 1.0 THEN 1.0
                ELSE MIN(CASE WHEN adj_raw > 1.0 THEN 1.0 ELSE adj_raw END) OVER (
                    PARTITION BY question_id, survey_name, peer_group_type, current_period_start
                    ORDER BY p_rank DESC
                    ROWS UNBOUNDED PRECEDING
                )
            END
    END AS adjusted_p_value,
    effect_size,
    CASE
        WHEN p_value IS NULL THEN 0
        WHEN MIN(CASE WHEN adj_raw > 1.0 THEN 1.0 ELSE adj_raw END) OVER (
            PARTITION BY question_id, survey_name, peer_group_type, current_period_start
            ORDER BY p_rank DESC
            ROWS UNBOUNDED PRECEDING
        ) < alpha THEN 1
        ELSE 0
    END AS statistically_significant_change_flag,
    practical_significance_flag,
    comparison_status_reason,
    fdr_family_size,
    SYSUTCDATETIME() AS calculated_at_utc
FROM adjusted
