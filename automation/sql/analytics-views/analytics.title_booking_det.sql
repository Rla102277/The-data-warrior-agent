


-- Create a view to represent title booking information
CREATE VIEW analytics.title_booking_det AS

-- Common Table Expression (CTE) to gather co-buyer information
WITH NSS_CoBuyers_CTE (SelectionID, Name, Email, CellPhone, HomePhone, WorkPhone, Row)  
AS (
    SELECT DISTINCT
        -- Selection ID from BuyerCoBuyers table
        NSS_BuyerCoBuyers.SelectionID, 
        -- Concatenate first and last names to create a full name
        NSS_ProspectCoBuyers.FirstName + ' ' + NSS_ProspectCoBuyers.LastName AS Name, 
        -- Use COALESCE to get the first non-null email (Home or Work)
        COALESCE(NSS_ProspectCoBuyers.HomeEmail, NSS_ProspectCoBuyers.WorkEmail) AS Email, 
        -- Cell phone number of the co-buyer
        NSS_ProspectCoBuyers.CellPhone AS CellPhone, 
        -- Home phone number of the co-buyer
        NSS_ProspectCoBuyers.HomePhone AS HomePhone, 
        -- Work phone number of the co-buyer
        NSS_ProspectCoBuyers.BusinessPhone AS WorkPhone, 
        -- Assign a row number for each co-buyer per selection
        ROW_NUMBER() OVER(PARTITION BY NSS_BuyerCoBuyers.SelectionID ORDER BY NSS_BuyerCoBuyers.BuyerCoBuyerID) AS Row 
    FROM 
        [SPLive].[dbo].[BuyerCoBuyers] NSS_BuyerCoBuyers 
    INNER JOIN 
        [SPLive].[dbo].[ProspectCoBuyers] NSS_ProspectCoBuyers 
        ON NSS_BuyerCoBuyers.CoBuyerID = NSS_ProspectCoBuyers.CoBuyerID
)

/********************************************************************************************************************************************************
    Main Query
 ********************************************************************************************************************************************************/

SELECT
    -- Selection ID from all selections
    NSS_AllSelections.SelectionID, 
    -- Unit code from the operating unit
    NSE_UnitCode.ounitcode AS oUnitCode, 
    -- Name of the operating unit
    NSE_UnitCode.[name] AS Operating_Name, 
    -- Name of the subdivision
    NSS_SubDivisions.[Name] AS SubDivision, 
    -- Project code from the project table
    NSE_Project.projcode AS ProjCode, 
    -- Project ID from the project table
    NSE_Project.projid AS ProjID, 
    -- Name of the project
    NSE_Project.[name] AS Project_Name, 
    -- Lot number from the lots table
    NSS_Lots.LotNo AS LotNo, 
    -- Full address combining Address1 and Address2 if available
    NSS_Lots.Address1 + CASE WHEN NSS_Lots.Address2 <> '' THEN ' ' + NSS_Lots.Address2 ELSE '' END AS Address, 
    -- Status of the lot
    NSS_Lots.LotStatus AS LotStatus, 
    -- Type of the lot
    NSS_Lots.LotType AS LotType, 
    -- Contract date for the selection
    NSS_AllSelections.ContractDate AS ContractDate, 
    -- Contract approval date for the selection
    NSS_AllSelections.ContractApprDate AS ContractApprDate, 
    -- Cancellation date for the selection
    NSS_AllSelections.CancelDate AS CancelDate, 
    -- Determine revised closing date, defaulting to user-defined date if null
    CASE WHEN NSE_JobSales.revisedclosing IS NULL OR NSE_JobSales.revisedclosing = '' THEN NSE_Lots.userdefdate##5 ELSE NSE_JobSales.revisedclosing END AS RevisedClosing, 
    -- Finance option for the selection
    NSS_AllSelections.FinanceOption AS Loan_Type, 
    -- Model code from the models table
    NSS_Models.ModelCode AS Model, 
    -- Elevation code from the models table
    NSS_Models.ElevCode AS Elev, 
    -- Description of the model
    NSS_Models.Descr AS Model_Description, 
    -- Swing information for the selection
    NSS_AllSelections.Swing AS Swing, 
    -- Square footage of the model
    NSS_Models.SquareFootage AS SqFt, 
    -- Full name of the buyer
    NSS_Prospects.FirstName + ' ' + NSS_Prospects.LastName AS Buyer_Name, 
    -- Placeholder for buyer email
    COALESCE(NSS_Prospects.HomeEmail,NSS_Prospects.WorkEmail) AS Buyer_Email, 
    -- Cell phone number of the buyer
    NSS_Prospects.CellPhone AS Buyer_CellPhone, 
    -- Home phone number of the buyer
    NSS_Prospects.HomePhone AS Buyer_HomePhone, 
    -- Work phone number of the buyer
    NSS_Prospects.BusinessPhone AS Buyer_WorkPhone, 
    -- Full name of the co-buyer from the CTE
    NSS_CoBuyers.Name AS CoBuyer_Name, 
    -- Placeholder for co-buyer email
    NSS_CoBuyers.Email AS CoBuyer_Email, 
    -- Cell phone number of the co-buyer
    NSS_CoBuyers.CellPhone AS CoBuyer_CellPhone, 
    -- Home phone number of the co-buyer
    NSS_CoBuyers.HomePhone AS CoBuyer_HomePhone, 
    -- Work phone number of the co-buyer
    NSS_CoBuyers.WorkPhone AS CoBuyer_WorkPhone, 
    -- Full name of the sales agent
    NSS_SalesAgent.FirstName + ' ' + NSS_SalesAgent.LastName AS Sales_Agent_Name, 
    -- Email of the sales agent
    NSS_SalesAgent.Email AS Sales_Agent_Email, 
    -- Cell phone number of the sales agent
    NSS_SalesAgent.CellPhone AS Sales_Agent_CellPhone, 
    -- Home phone number of the sales agent
    NSS_SalesAgent.HomePhone AS Sales_Agent_HomePhone, 
    -- Work phone number of the sales agent
    NSS_SalesAgent.BusinessPhone AS Sales_Agent_WorkPhone, 
    -- Determine realtor name based on selection ID presence
    CASE WHEN NSS_BuyerREAgents.SelectionID IS NOT NULL THEN CAST(LTRIM(NSS_REAgents.FirstName + ' ' + NSS_REAgents.LastName) AS NVARCHAR(200)) ELSE NSS_ProspectREAgent.FirstName + ' ' + NSS_ProspectREAgent.LastName END AS Realtor_Name, 
    -- Email of the realtor
    NSS_REAgents.Email Realtor_Email, 
    -- Cell phone number of the realtor
    NSS_REAgents.CellPhone Realtor_CellPhone, 
    -- Home phone number of the realtor
    NSS_REAgents.HomePhone Realtor_HomePhone, 
    -- Work phone number of the realtor
    NSS_REAgents.BusinessPhone Realtor_WorkPhone, 
    -- Name of the lender
    NSS_Lenders.[Name] Lender_Name, 
    -- Email for all invites
    NSS_Lenders.Email Lender_Email, 
    -- Phone number of the lender
    NSS_Lenders.Phone Lender_Phone, 
    -- Full name of the loan officer
    NSS_LoanOfficer.FirstName + ' ' + NSS_LoanOfficer.LastName Loan_Officer_Name, 
    -- Email of the loan officer
    NSS_LoanOfficer.Email Loan_Officer_Email, 
    -- Phone number of the loan officer
    NSS_LoanOfficer.Phone Loan_Officer_Phone, 
    -- Name of the title company
    NSS_TitleCompanies.[Name] Title_Company, 
    -- Email for all invites
    'Closings-All@greenbrickpartners.com' Invite_Email_All, 
    -- Conditional email based on unit code
    CASE NSE_UnitCode.ounitcode
        WHEN '0003' THEN 'ClosingsBuilder-CBJ@greenbrickpartners.com'
        WHEN '0004' THEN 'ClosingsBuilder-CLH@greenbrickpartners.com'
        WHEN '0011' THEN 'ClosingsBuilder-TSH@greenbrickpartners.com'
        ELSE NULL 
    END Invite_Email_Builder 
FROM 
    [HBLive].[rems].[operunit] NSE_UnitCode 
INNER JOIN 
    [HBLive].[rems].[project] NSE_Project ON NSE_UnitCode.ounitcode = (CASE WHEN NSE_Project.userdef##10 <> '' THEN NSE_Project.userdef##10 ELSE NSE_Project.ounitcode END)
INNER JOIN 
    [SPLive].[dbo].[Subdivisions] NSS_SubDivisions ON NSE_Project.projid = NSS_SubDivisions.i_ProjID
INNER JOIN 
    [SPLive].[dbo].[SDLots] NSS_Lots ON NSS_SubDivisions.SubdivisionID = NSS_Lots.SubdivisionID

-- Sales Details
INNER JOIN (
    SELECT
        -- Selection ID from BuyerSelections
        NSS_BuyerSelections.SelectionID, 
        -- SDLotID from BuyerSelections
        NSS_BuyerSelections.SDLotID AS SDLotID, 
        -- Subdivision ID from BuyerSelections
        NSS_BuyerSelections.SubdivisionID AS SubdivisionID, 
        -- SDModelID from BuyerSelections
        NSS_BuyerSelections.SDModelID AS SDModelID, 
        -- Swing information from BuyerSelections
        NSS_BuyerSelections.Swing AS Swing, 
        -- Prospect ID from BuyerSelections
        NSS_BuyerSelections.ProspectID AS ProspectID, 
        -- Lender ID from BuyerSelections
        NSS_BuyerSelections.LenderID AS LenderID, 
        -- Title Company ID from BuyerSelections
        NSS_BuyerSelections.TitleCompanyID AS TitleCompanyID, 
        -- Contract date from BuyerSelections
        NSS_BuyerSelections.ContractDate AS ContractDate, 
        -- Contract approval date from BuyerSelections
        NSS_BuyerSelections.ContractApprDate AS ContractApprDate, 
        -- Placeholder for CancelDate
        NULL AS CancelDate, 
        -- Actual closing date from BuyerSelections
        NSS_BuyerSelections.ClosingActualDate AS ClosingActualDate, 
        -- Name on title from BuyerSelections
        NSS_BuyerSelections.NameOnTitle AS NameOnTitle, 
        -- Loan officer from BuyerSelections
        NSS_BuyerSelections.LoanOfficer AS LoanOfficer, 
        -- Finance option from BuyerSelections
        NSS_BuyerSelections.FinanceOption AS FinanceOption, 
        -- Loan officer ID from BuyerSelections
        NSS_BuyerSelections.LoanOfficerID AS LoanOfficerID 
    FROM 
        [SPLive].[dbo].[BuyerSelections] NSS_BuyerSelections
    WHERE 
        -- Ensure contract approval or submission date is not null
        (NSS_BuyerSelections.ContractApprDate IS NOT NULL OR NSS_BuyerSelections.ContractSubmitDate IS NOT NULL) 
        -- Ensure cancellation date is null
        AND NSS_BuyerSelections.CancelDate IS NULL 
) NSS_AllSelections ON NSS_Lots.SDLotID = NSS_AllSelections.SDLotID

-- Supporting NewStar Sales tables
LEFT JOIN [SPLive].[dbo].[SalesOffices] NSS_SalesOffices ON NSS_SubDivisions.SalesOfficeID = NSS_SalesOffices.SalesOfficeID
LEFT JOIN [SPLive].[dbo].[SDModels] NSS_Models ON NSS_AllSelections.SDModelID = NSS_Models.SDModelID
LEFT JOIN [SPLive].[dbo].[Prospects] NSS_Prospects ON NSS_AllSelections.ProspectID = NSS_Prospects.ProspectID
LEFT JOIN [SPLive].[dbo].[Lenders] NSS_Lenders ON NSS_AllSelections.LenderID = NSS_Lenders.LenderID
LEFT JOIN [SPLive].[dbo].[TitleCompanies] NSS_TitleCompanies ON NSS_AllSelections.TitleCompanyID = NSS_TitleCompanies.TitleCompanyID
LEFT JOIN [SPLive].[dbo].[Users] NSS_SalesAgent ON NSS_Prospects.UserID = NSS_SalesAgent.UserID
LEFT JOIN [SPLive].[dbo].[REAgents] NSS_ProspectREAgent ON NSS_Prospects.REAgentID = NSS_ProspectREAgent.REAgentID
LEFT JOIN [SPLive].[dbo].[LoanOfficer] NSS_LoanOfficer ON NSS_LoanOfficer.LoanofficerID = NSS_AllSelections.LoanOfficerID

-- Supporting NewStar Enterprise tables
LEFT JOIN [HBLive].[rems].[jobphase] NSE_Lots ON NSE_Project.projid = NSE_Lots.projid AND NSS_Lots.LotNo = NSE_Lots.phase
LEFT JOIN [HBLive].[rems].[jobsales] NSE_JobSales ON NSS_SubDivisions.i_ProjID = NSE_JobSales.projid
    AND CASE WHEN NSS_AllSelections.CancelDate IS NOT NULL THEN NULL ELSE NSS_Lots.LotNo END = NSE_JobSales.phase    

-- Join with the CTE for co-buyers
LEFT JOIN NSS_CoBuyers_CTE NSS_CoBuyers ON NSS_AllSelections.SelectionID = NSS_CoBuyers.SelectionID AND NSS_CoBuyers.Row = 1
LEFT JOIN [SPLive].[dbo].[BuyerREAgents] NSS_BuyerREAgents ON NSS_AllSelections.SelectionID = NSS_BuyerREAgents.SelectionID AND NSS_BuyerREAgents.SeqNo = 1
LEFT JOIN [SPLive].[dbo].[REAgents] NSS_REAgents ON NSS_BuyerREAgents.REAgentID = NSS_REAgents.REAgentID
LEFT JOIN [SPLive].[dbo].[REAgencies] NSS_REAgencies ON NSS_REAgents.REAgencyID = NSS_REAgencies.REAgencyID

WHERE (NSS_AllSelections.ClosingActualDate IS NULL) --OR NSS_AllSelections.ClosingActualDate >= DATEADD(m, -6, GETDATE()))
    AND (NSE_Lots.userdeflog##1 = 0 AND NSE_Project.userdeflog##2 = 0) 

