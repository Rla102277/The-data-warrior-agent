# Community geo review (Market Intelligence proximity)

**As of:** 2026-09-17  
**Workspace:** Foundation Development only  
**Seed:** `python3 -u automation/seed_web_community_geo.py`  
**Review CSV:** [`automation/logs/web_community_geo_review.csv`](../../automation/logs/web_community_geo_review.csv)

## What this is

Centroids in `control.web_community_geo` drive **proximity enrichment** around Green Brick communities (Peer Arena membership is Dataverse peers, not geo):

- **primary** <= 3 miles
- **secondary** 3 to 5 miles
- **same_community** name match

Only `geo_confidence` in (`high`, `medium`) participates in distance rings. Manual pins are preferred.

## How to fix a bad pin

1. Open the review CSV and find the community.
2. Prefer adding / updating `MANUAL_PINS` in `automation/seed_web_community_geo.py`, then re-seed.
3. Or update `control.web_community_geo` with correct lat/lon, `geo_method = 'manual'`, `geo_confidence = 'high'`.
4. Redeploy `community_proximity_map` + `competitor_position_obt`, run `pipeline_operations_analytics_refresh` `p_domain=operations`, refresh the Market Intelligence semantic model.

City-centroid rows that still share one city pin will show **0.0 miles** until refined.

## 2026-09-17 city-centroid fixes (confirmed from builder sales offices)

| Community | Was (wrong city) | Corrected pin |
|---|---|---|
| Cibolo Hills West | Aubrey city centroid | Fort Worth 32.9239, -97.4289 (11033 Cottonbowl Dr) |
| Eastridge Premier / Signature | Forney city centroid | McKinney 33.2316, -96.5138 (404 Watertown Dr) |
| Stonehaven | Frisco city centroid | Seagoville 32.6840, -96.5537 (2132 Lone Star Ln) |
| Star Trail | Prosper shared pin | Prosper 33.2409, -96.8306 (Nominatim) |

## Seeded snapshot

- Manual pins preferred for MVP corridor communities
- GBP focals remain high confidence
- Re-run seed after MANUAL_PINS edits; review CSV regenerates each seed

Do not enable schedules for geo refresh until Ops signs off on the MVP pins.
