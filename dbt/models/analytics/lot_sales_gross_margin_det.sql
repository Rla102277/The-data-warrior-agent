{{ config(materialized='view', schema='analytics', alias='lot_sales_gross_margin_det') }}

SELECT * FROM {{ source('transform', 'lot_sales_gross_margin_det') }}
