

CREATE VIEW vw_rep_lot_financials_summary AS

SELECT 
    lot_id,
    COALESCE([Base Revenue],0) AS [Base Revenue],
    COALESCE([Total Incentives],0) AS [Total Incentives],
    COALESCE([Closing Costs HBW],0) AS [Closing Costs HBW],
    COALESCE([Design Option Cost],0) AS [Design Option Cost],
    COALESCE([Sales Options],0) AS [Sales Options],
    COALESCE([Unclassified Indirect],0) AS [Unclassified Indirect],
    COALESCE([Site Conditions],0) AS [Site Conditions],
    COALESCE([Taxes-Insurance-HOA-Utilities],0) AS [Taxes-Insurance-HOA-Utilities],
    COALESCE([Custom Option Cost],0) AS [Custom Option Cost],
    COALESCE([Commissions internal],0) AS [Commissions internal],
    COALESCE([Design Options],0) AS [Design Options],
    COALESCE([Lot Premium],0) AS [Lot Premium],
    COALESCE([Sales Option Cost],0) AS [Sales Option Cost],
    COALESCE([Variance],0) AS [Variance],
    COALESCE([Lot Closing Cost],0) AS [Lot Closing Cost],
    COALESCE([Shared Community Cost],0) AS [Shared Community Cost],
    COALESCE([Unclassified Cost],0) AS [Unclassified Cost],
    COALESCE([Commissions external],0) AS [Commissions external],
    COALESCE([Warranty],0) AS [Warranty],
    COALESCE([Custom Options],0) [Custom Options],
    COALESCE([Const Loan Interest JBGL],0) AS [Const Loan Interest JBGL],
    COALESCE([Direct Const Costs Base],0) AS [Direct Const Costs Base],
    [Net_Revenue] = COALESCE([Base Revenue],0) + COALESCE([Lot Premium],0) + COALESCE([Sales Options],0) + COALESCE([Design Options],0) + COALESCE([Custom Options],0) - COALESCE([Total Incentives],0),
    sqft AS SQFT_from_Sale
FROM (
    SELECT 
        lf.lot_id,
        ds.sqft,
        sgm_type_description,
        COALESCE(latest_est_amount,0) AS latest_est_amount
    FROM [EDW_Gold].[dbo].[vw_fact_lot_financials_active] lf
        LEFT JOIN [EDW_Gold].[dbo].[vw_dim_sale_active] ds
            ON ds.lot_id = lf.lot_id
            AND ds.sales_status NOT IN ('Cancelled','Transfer')
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
) AS pvt;
