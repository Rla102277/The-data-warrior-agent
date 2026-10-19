/*
  analytics.customer_survey_obt

  Rebuild of Operations CustomerSatisfactionSurveyResults_Prod semantic model
  as one big table for Foundation Development consumption.

  Grain: one row per survey question response (dataverse gbp_reponse).
  Sources:
    - dataverse_gbpdev shortcuts to GBP-Enterprise dataverse_gbpprod tables
    - analytics.sale_active / lot_active / project_active / operating_unit_active
  Operations workspace is untouched (copy/rebuild in Foundation Development only).
*/

CREATE OR ALTER VIEW analytics.customer_survey_obt
AS
SELECT
    -- response (fact grain)
    r.Id                              AS response_id,
    r.gbp_reponse                     AS response_text,
    r.gbp_surveyresponse              AS survey_response_id,
    r.gbp_question                    AS question_id,
    COALESCE(r.gbp_customer, sr.gbp_customer) AS customer_id,
    CASE
        WHEN q.gbp_questiontype = 803570000 THEN TRY_CAST(r.gbp_reponse AS FLOAT)
        ELSE NULL
    END                               AS rating_value,
    CASE q.gbp_questiontype
        WHEN 803570000 THEN 'Rating'
        WHEN 803570003 THEN 'Multiple Choice'
        WHEN 803570001 THEN 'Text'
        WHEN 803570002 THEN 'Yes/No'
        ELSE 'Unknown'
    END                               AS question_type_name,
    r.createdon                       AS response_created_on,
    r.modifiedon                      AS response_modified_on,

    -- survey response
    sr.gbp_name                       AS survey_response_name,
    sr.gbp_surveyname                 AS survey_name_raw,
    CASE
        WHEN sr.gbp_surveyname IN ('Move-In (Full)', 'Move In', 'Move-In Evaluation') THEN 'Move-In'
        WHEN sr.gbp_surveyname IN ('6 Months After Move-in', 'Mid-Year') THEN 'Mid-Year'
        WHEN sr.gbp_surveyname IN ('12 Months After Move-in', 'Year-End') THEN 'Year-End'
        WHEN sr.gbp_surveyname LIKE '%Closing%' THEN 'Closing'
        ELSE NULL
    END                               AS survey_name,
    sr.createdon                      AS survey_sent_on,
    sr.gbp_datecompleted              AS survey_completed_on,
    sr.gbp_expiredate                 AS survey_expire_on,

    -- question
    q.gbp_name                        AS question_name,
    q.gbp_categoryname                AS question_category,
    q.gbp_questiontype                AS question_type_code,

    -- customer
    c.gbp_closedate                   AS customer_close_date,
    TRY_CAST(c.gbp_sale_id AS BIGINT) AS sale_id,

    -- sale / lot / project / operating unit (operations dims)
    s.sales_status,
    s.sale_type,
    s.buyer_name,
    s.buyer_email,
    COALESCE(s.buyer_cell_phone, s.buyer_home_phone, s.buyer_work_phone) AS buyer_phone,
    s.sales_agent,
    s.approved_date,
    s.cancel_date,
    s.contract_date,
    s.lot_id,
    s.project_id,
    l.lot_number,
    l.street,
    l.city,
    l.state,
    l.zip,
    CONCAT(l.street, ', ', l.city, ', ', l.state, ' ', l.zip) AS address,
    l.close_date                      AS lot_close_date,
    p.project_code,
    p.project_name,
    p.operating_unit_code,
    p.reporting_operating_unit_code,
    u.operating_unit_name,
    u.operating_unit_label
FROM dataverse_gbpdev.dbo.gbp_reponse AS r
LEFT JOIN dataverse_gbpdev.dbo.gbp_surveyresponse AS sr
    ON r.gbp_surveyresponse = sr.Id
LEFT JOIN dataverse_gbpdev.dbo.gbp_question AS q
    ON r.gbp_question = q.Id
LEFT JOIN dataverse_gbpdev.dbo.gbp_customer AS c
    ON COALESCE(r.gbp_customer, sr.gbp_customer) = c.Id
LEFT JOIN analytics.sale_active AS s
    ON TRY_CAST(c.gbp_sale_id AS BIGINT) = s.sale_id
LEFT JOIN analytics.lot_active AS l
    ON s.lot_id = l.lot_id
LEFT JOIN analytics.project_active AS p
    ON s.project_id = p.project_id
LEFT JOIN analytics.operating_unit_active AS u
    ON p.reporting_operating_unit_code = u.operating_unit_code;
