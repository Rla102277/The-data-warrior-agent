{{ config(materialized='view', schema='analytics', alias='lot_financials_sum', tags=['unpublished','wrapper']) }}

-- Unpublished Gold-name wrapper. Wide lot financials live on lot_financials_obt.

SELECT
    lot_id,
    base_revenue AS [Base Revenue],
    total_incentives AS [Total Incentives],
    closing_costs_hbw AS [Closing Costs HBW],
    design_option_cost AS [Design Option Cost],
    sales_options AS [Sales Options],
    unclassified_indirect AS [Unclassified Indirect],
    site_conditions AS [Site Conditions],
    taxes_insurance_hoa_utilities AS [Taxes-Insurance-HOA-Utilities],
    custom_option_cost AS [Custom Option Cost],
    commissions_internal AS [Commissions internal],
    design_options AS [Design Options],
    lot_premium AS [Lot Premium],
    sales_option_cost AS [Sales Option Cost],
    variance AS [Variance],
    lot_closing_cost AS [Lot Closing Cost],
    shared_community_cost AS [Shared Community Cost],
    unclassified_cost AS [Unclassified Cost],
    commissions_external AS [Commissions external],
    warranty AS [Warranty],
    custom_options AS [Custom Options],
    const_loan_interest_jbgl AS [Const Loan Interest JBGL],
    direct_const_costs_base AS [Direct Const Costs Base],
    net_revenue AS Net_Revenue,
    sqft AS SQFT_from_Sale
FROM {{ ref('lot_financials_obt') }}
