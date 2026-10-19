{{ config(materialized='view', schema='analytics', alias='sales_sum_weekly') }}

-- Grain: operating unit + week_start + event_type.

SELECT
    e.operating_unit_code,
    e.operating_unit_name,
    e.operating_unit_short_code,
    e.week_start_date,
    e.event_category,
    e.event_type,
    SUM(e.event_value) AS event_count,
    SUM(CASE WHEN e.event_type = 'Sale' THEN e.event_value ELSE 0 END) AS sales,
    SUM(CASE WHEN e.event_category = 'Cancels' THEN e.event_value ELSE 0 END) AS cancels,
    SUM(CASE WHEN e.event_type = 'Sale' THEN e.event_value ELSE 0 END)
        - SUM(CASE WHEN e.event_category = 'Cancels' THEN e.event_value ELSE 0 END) AS net_sales,
    SUM(CASE WHEN e.event_type = 'Close' THEN e.event_value ELSE 0 END) AS closings,
    SUM(CASE WHEN e.event_type = '1-Job Started' THEN e.event_value ELSE 0 END) AS starts,
    SUM(e.net_revenue) AS net_revenue,
    SUM(e.sqft) AS sqft
FROM {{ ref('lot_events_obt') }} e
WHERE e.week_start_date IS NOT NULL
GROUP BY
    e.operating_unit_code,
    e.operating_unit_name,
    e.operating_unit_short_code,
    e.week_start_date,
    e.event_category,
    e.event_type
