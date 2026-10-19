{{ config(materialized='view', schema='analytics', alias='lot_financials_obt') }}

-- One row per lot: SGM types pivoted wide, plus project / operating unit.
-- Line grain stays on lot_financials_det.

SELECT
    pvt.lot_id,
    l.lot_number,
    l.lot_status,
    p.project_id,
    p.project_code,
    p.project_name,
    ou.operating_unit_code,
    ou.operating_unit_name,
    ou.brand_short_code AS operating_unit_short_code,
    COALESCE(pvt.[Base Revenue], 0) AS base_revenue,
    COALESCE(pvt.[Total Incentives], 0) AS total_incentives,
    COALESCE(pvt.[Closing Costs HBW], 0) AS closing_costs_hbw,
    COALESCE(pvt.[Design Option Cost], 0) AS design_option_cost,
    COALESCE(pvt.[Sales Options], 0) AS sales_options,
    COALESCE(pvt.[Unclassified Indirect], 0) AS unclassified_indirect,
    COALESCE(pvt.[Site Conditions], 0) AS site_conditions,
    COALESCE(pvt.[Taxes-Insurance-HOA-Utilities], 0) AS taxes_insurance_hoa_utilities,
    COALESCE(pvt.[Custom Option Cost], 0) AS custom_option_cost,
    COALESCE(pvt.[Commissions internal], 0) AS commissions_internal,
    COALESCE(pvt.[Design Options], 0) AS design_options,
    COALESCE(pvt.[Lot Premium], 0) AS lot_premium,
    COALESCE(pvt.[Sales Option Cost], 0) AS sales_option_cost,
    COALESCE(pvt.[Variance], 0) AS variance,
    COALESCE(pvt.[Lot Closing Cost], 0) AS lot_closing_cost,
    COALESCE(pvt.[Shared Community Cost], 0) AS shared_community_cost,
    COALESCE(pvt.[Unclassified Cost], 0) AS unclassified_cost,
    COALESCE(pvt.[Commissions external], 0) AS commissions_external,
    COALESCE(pvt.[Warranty], 0) AS warranty,
    COALESCE(pvt.[Custom Options], 0) AS custom_options,
    COALESCE(pvt.[Const Loan Interest JBGL], 0) AS const_loan_interest_jbgl,
    COALESCE(pvt.[Direct Const Costs Base], 0) AS direct_const_costs_base,
    COALESCE(pvt.[Base Revenue], 0)
        + COALESCE(pvt.[Lot Premium], 0)
        + COALESCE(pvt.[Sales Options], 0)
        + COALESCE(pvt.[Design Options], 0)
        + COALESCE(pvt.[Custom Options], 0)
        - COALESCE(pvt.[Total Incentives], 0) AS net_revenue,
    pvt.sqft
FROM (
    SELECT
        lf.lot_id,
        ds.sqft,
        lf.sgm_type_description,
        COALESCE(lf.latest_est_amount, 0) AS latest_est_amount
    FROM {{ ref('lot_financials_det') }} lf
        LEFT JOIN (
            SELECT
                s.lot_id,
                s.sqft,
                ROW_NUMBER() OVER (
                    PARTITION BY s.lot_id
                    ORDER BY COALESCE(s.approved_date, s.contract_date) DESC, s.sale_id DESC
                ) AS rn
            FROM {{ ref('sale') }} s
            WHERE s.sales_status NOT IN ('Cancelled', 'Transfer')
        ) ds
            ON ds.lot_id = lf.lot_id
            AND ds.rn = 1
) AS source
PIVOT (
    SUM(latest_est_amount)
    FOR sgm_type_description IN (
        [Base Revenue],
        [Total Incentives],
        [Closing Costs HBW],
        [Design Option Cost],
        [Sales Options],
        [Unclassified Indirect],
        [Site Conditions],
        [Taxes-Insurance-HOA-Utilities],
        [Custom Option Cost],
        [Commissions internal],
        [Design Options],
        [Lot Premium],
        [Sales Option Cost],
        [Variance],
        [Lot Closing Cost],
        [Shared Community Cost],
        [Unclassified Cost],
        [Commissions external],
        [Warranty],
        [Custom Options],
        [Const Loan Interest JBGL],
        [Direct Const Costs Base]
    )
) AS pvt
INNER JOIN {{ ref('lot') }} l
    ON l.lot_id = pvt.lot_id
INNER JOIN {{ ref('project') }} p
    ON p.project_id = l.project_id
INNER JOIN {{ ref('operating_unit') }} ou
    ON ou.operating_unit_code = p.reporting_operating_unit_code
WHERE l.exclude_from_reporting = 0
