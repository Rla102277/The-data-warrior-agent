{{ config(materialized='view', schema='analytics', alias='sale_obt') }}

-- One row per current sale: sale + lot + project + operating unit + current job.
-- Replaces the misnamed sales_det (that model was a filtered sale join, not a DET).

WITH current_job AS (
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
    s.sale_id,
    s.sale_guid,
    s.sales_status,
    s.sale_type,
    s.sqft,
    s.buyer_name,
    s.buyer_email,
    s.cobuyer_names,
    s.sales_agent,
    s.realtor_name,
    s.agency_name,
    s.lender,
    s.loan_type,
    s.title_company,
    s.total_deposits_due,
    s.deposits_paid,
    s.contract_date,
    s.submit_date,
    s.approved_date,
    s.cancel_date,
    s.cancel_code,
    s.cancel_reason,
    s.is_contingent,
    s.is_transfer_to,
    s.is_transfer_from,
    s.lot_id,
    l.lot_number,
    l.lot_status,
    l.lot_type,
    l.street,
    l.city,
    l.state,
    l.zip,
    l.plan_code,
    l.plan_description,
    l.elevation,
    l.base_square_footage,
    l.lot_premium,
    l.close_date AS lot_close_date,
    l.revised_close_date,
    l.is_backlog,
    l.is_spec,
    l.is_started,
    l.is_completed,
    l.sold_not_started,
    s.project_id,
    p.project_code,
    p.project_name,
    p.project_type,
    p.reporting_operating_unit_code,
    ou.operating_unit_code,
    ou.operating_unit_name,
    ou.operating_unit_label,
    ou.brand_short_code AS operating_unit_short_code,
    j.job_id,
    j.job_status,
    j.start_date AS job_start_date,
    j.complete_date AS job_complete_date
FROM {{ ref('sale') }} s
INNER JOIN {{ ref('lot') }} l
    ON l.lot_id = s.lot_id
INNER JOIN {{ ref('project') }} p
    ON p.project_id = s.project_id
INNER JOIN {{ ref('operating_unit') }} ou
    ON ou.operating_unit_code = p.reporting_operating_unit_code
LEFT JOIN current_job j
    ON j.lot_id = s.lot_id AND j.rn = 1
