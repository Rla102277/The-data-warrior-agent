{{ config(materialized='view', schema='analytics', alias='sales_det', tags=['unpublished','wrapper']) }}

-- Unpublished Gold-name wrapper. Use sale_obt (1 row per current sale).

SELECT * FROM {{ ref('sale_obt') }}
