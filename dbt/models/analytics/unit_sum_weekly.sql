{{ config(materialized='view', schema='analytics', alias='unit_sum_weekly') }}

-- Grain: operating unit + week_start.
-- starts / completions / closings are week-sliced.
-- backlog / sold_not_started / specs are current-state inventory (filled only on is_current_week).

WITH starts AS (
    SELECT operating_unit_code, week_start_date, SUM(event_value) AS starts
    FROM {{ ref('lot_events_obt') }}
    WHERE event_type = '1-Job Started'
      AND week_start_date IS NOT NULL
    GROUP BY operating_unit_code, week_start_date
),
closings AS (
    SELECT operating_unit_code, week_start_date, SUM(event_value) AS closings
    FROM {{ ref('lot_events_obt') }}
    WHERE event_type = 'Close'
      AND week_start_date IS NOT NULL
    GROUP BY operating_unit_code, week_start_date
),
completions AS (
    SELECT
        ou.operating_unit_code,
        cal.week_start_date,
        COUNT(*) AS completions
    FROM {{ ref('job') }} j
    INNER JOIN {{ ref('lot') }} l
        ON l.lot_id = j.lot_id
    INNER JOIN {{ ref('project') }} p
        ON p.project_id = l.project_id
    INNER JOIN {{ ref('operating_unit') }} ou
        ON ou.operating_unit_code = p.reporting_operating_unit_code
    INNER JOIN {{ source('transform', 'calendar') }} cal
        ON cal.full_date = CAST(j.complete_date AS DATE)
    WHERE j.complete_date IS NOT NULL
      AND l.exclude_from_reporting = 0
    GROUP BY ou.operating_unit_code, cal.week_start_date
),
weeks AS (
    SELECT operating_unit_code, week_start_date FROM starts
    UNION
    SELECT operating_unit_code, week_start_date FROM closings
    UNION
    SELECT operating_unit_code, week_start_date FROM completions
),
inventory AS (
    SELECT
        ou.operating_unit_code,
        SUM(CASE WHEN l.is_backlog = 1 THEN 1 ELSE 0 END) AS backlog,
        SUM(CASE WHEN l.sold_not_started = 1 THEN 1 ELSE 0 END) AS sold_not_started,
        SUM(CASE WHEN l.is_spec = 1 THEN 1 ELSE 0 END) AS specs
    FROM {{ ref('lot') }} l
    INNER JOIN {{ ref('project') }} p
        ON p.project_id = l.project_id
    INNER JOIN {{ ref('operating_unit') }} ou
        ON ou.operating_unit_code = p.reporting_operating_unit_code
    WHERE l.exclude_from_reporting = 0
    GROUP BY ou.operating_unit_code
),
current_week AS (
    SELECT MAX(week_start_date) AS week_start_date FROM weeks
)
SELECT
    w.operating_unit_code,
    ou.operating_unit_name,
    ou.brand_short_code AS operating_unit_short_code,
    w.week_start_date,
    CASE WHEN w.week_start_date = cw.week_start_date THEN 1 ELSE 0 END AS is_current_week,
    COALESCE(s.starts, 0) AS starts,
    COALESCE(x.completions, 0) AS completions,
    COALESCE(c.closings, 0) AS closings,
    CASE WHEN w.week_start_date = cw.week_start_date THEN i.backlog ELSE NULL END AS backlog,
    CASE WHEN w.week_start_date = cw.week_start_date THEN i.sold_not_started ELSE NULL END AS sold_not_started,
    CASE WHEN w.week_start_date = cw.week_start_date THEN i.specs ELSE NULL END AS specs
FROM weeks w
INNER JOIN {{ ref('operating_unit') }} ou
    ON ou.operating_unit_code = w.operating_unit_code
LEFT JOIN starts s
    ON s.operating_unit_code = w.operating_unit_code
    AND s.week_start_date = w.week_start_date
LEFT JOIN closings c
    ON c.operating_unit_code = w.operating_unit_code
    AND c.week_start_date = w.week_start_date
LEFT JOIN completions x
    ON x.operating_unit_code = w.operating_unit_code
    AND x.week_start_date = w.week_start_date
LEFT JOIN inventory i
    ON i.operating_unit_code = w.operating_unit_code
CROSS JOIN current_week cw
