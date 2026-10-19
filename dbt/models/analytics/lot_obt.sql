{{ config(materialized='view', schema='analytics', alias='lot_obt') }}

-- One row per current lot: lot + project + operating unit + current sale + current job.

WITH current_sale AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (
            PARTITION BY s.lot_id
            ORDER BY COALESCE(s.approved_date, s.contract_date) DESC, s.sale_id DESC
        ) AS rn
    FROM {{ ref('sale') }} s
    WHERE s.sales_status NOT IN ('Cancelled', 'Transfer')
),
current_job AS (
    SELECT
        j.*,
        ROW_NUMBER() OVER (
            PARTITION BY j.lot_id
            ORDER BY COALESCE(j.start_date, j.planned_start_date) DESC, j.job_id DESC
        ) AS rn
    FROM {{ ref('job') }} j
    WHERE j.job_active = 1
)
SELECT
    l.lot_id,
    l.lot_guid,
    l.lot_number,
    l.lot_label,
    l.lot_status,
    l.lot_type,
    l.street,
    l.street2,
    l.city,
    l.state,
    l.zip,
    l.plan_code,
    l.plan_description,
    l.elevation,
    l.base_square_footage,
    l.lot_premium,
    l.permit_date,
    l.release_date,
    l.revised_close_date,
    l.close_date,
    l.close_reporting_date,
    l.is_backlog,
    l.is_closed,
    l.is_spec,
    l.is_model,
    l.is_owned,
    l.is_started,
    l.is_completed,
    l.sold_not_started,
    l.exclude_from_reporting,
    p.project_id,
    p.project_code,
    p.project_name,
    p.project_type,
    p.reporting_operating_unit_code,
    ou.operating_unit_code,
    ou.operating_unit_name,
    ou.operating_unit_label,
    ou.brand_short_code AS operating_unit_short_code,
    s.sale_id,
    s.sale_guid,
    s.sales_status,
    s.sale_type,
    s.sqft AS sale_sqft,
    s.buyer_name,
    s.sales_agent,
    s.contract_date,
    s.approved_date,
    s.cancel_date,
    j.job_id,
    j.job_guid,
    j.job_status,
    j.construction_manager,
    j.start_date AS job_start_date,
    j.complete_date AS job_complete_date,
    j.planned_start_date,
    j.planned_complete_date
FROM {{ ref('lot') }} l
INNER JOIN {{ ref('project') }} p
    ON p.project_id = l.project_id
INNER JOIN {{ ref('operating_unit') }} ou
    ON ou.operating_unit_code = p.reporting_operating_unit_code
LEFT JOIN current_sale s
    ON s.lot_id = l.lot_id AND s.rn = 1
LEFT JOIN current_job j
    ON j.lot_id = l.lot_id AND j.rn = 1
WHERE l.exclude_from_reporting = 0
