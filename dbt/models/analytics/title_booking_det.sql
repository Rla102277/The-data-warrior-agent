{{ config(materialized='view', schema='analytics', alias='title_booking_det', tags=['unpublished','wrapper']) }}

-- Unpublished Gold-name wrapper. Use title_booking_obt (1 row per selection).

SELECT * FROM {{ ref('title_booking_obt') }}
