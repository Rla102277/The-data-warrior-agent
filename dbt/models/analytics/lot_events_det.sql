{{ config(materialized='view', schema='analytics', alias='lot_events_det', tags=['unpublished','wrapper']) }}

-- Unpublished Gold-name wrapper. Use lot_events_obt (1 row per lot-event).

SELECT * FROM {{ ref('lot_events_obt') }}
