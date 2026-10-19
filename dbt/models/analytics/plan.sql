{{ config(materialized='view', schema='analytics', alias='plan') }}

SELECT project_id = JM.projid,
    plan_code = JM.model,
    elev = JM.elev,
    plan_name = JM.descr,
    base_price = PPE.unitprice,
    active = CASE JM.discontinued WHEN 1 THEN 0 ELSE 1 END,
    bedrooms = JM.bedrooms,
    full_bathrooms = JM.noofbaths,
    half_bathrooms = noofhalfbaths,
    square_footage = JM.area,
    stories = JM.stories,
    garage_spaces = JM.noofgarages,
    last_modified = CASE WHEN PPE.lastmoddatetime > JM.lastmoddatetime THEN PPE.lastmoddatetime ELSE JM.lastmoddatetime END
    FROM HBLive.rems.jobmodel JM
        INNER JOIN HBLive.rems.slprodprice PP ON
            PP.projid = JM.projid
            AND PP.model = JM.model
            AND PP.elev = JM.elev
        INNER JOIN HBLive.rems.slproduct PL ON
            PL.prodid = PP.prodid
            AND PL.prodcode = '0000Base'
        INNER JOIN (
            SELECT Num = Row_Number() OVER (Partition By PPE.projid, PPE.model, PPE.elev, PPE.prodid Order BY PPE.effdate Desc)
                ,PPE.projid
                ,PPE.model
                ,PPE.elev
                ,PPE.prodid
                ,PPE.unitprice
                ,PPE.qty
                ,PPE.effdate
                ,PPE.lastmoddatetime
            FROM HBLive.rems.slprodeffdate PPE
                WHERE PPE.effdate < DATEADD(d,0,GETDATE())
        )AS PPE ON
            PPE.projid = PP.projid
            AND PPE.model = PP.model
            AND PPE.elev = PP.elev
            AND PPE.prodid = PP.prodid
            AND PPE.Num = 1
