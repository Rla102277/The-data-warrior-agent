# Foundation Market Intelligence

**Product name:** Foundation Market Intelligence  
**Workspace:** Foundation Development only  
**Status:** MVP (2026-09-17)  
**Schedules:** OFF until smoke pack is green 5 consecutive on-demand days  
**Smoke:** `automation/run_market_intelligence_mvp_smoke.py` **14/15** on 2026-09-18 (peer projects + scanning peers + GBP benchmark + proximity; coverage still flags some stale MVP scrapes)  
**Report:** https://app.fabric.microsoft.com/groups/40502864-6ece-49b5-807f-6f7c11d1b3e1/reports/0d4b2bd0-74c8-48f4-9140-9e1bb1f49ee9  

Companion: [`web-scrape-user-manual.md`](web-scrape-user-manual.md), MVP freeze [`automation/web_scrape/market_intelligence_mvp.json`](../../automation/web_scrape/market_intelligence_mvp.json), geo review [`market-intelligence-geo-review.md`](market-intelligence-geo-review.md), Cursor MCP [`market-intelligence-mcp.md`](market-intelligence-mcp.md) (`automation/mcp_market_intelligence`).

## Promise

For a frozen set of mapped DFW communities, an analyst opens one Power BI app and can see:

1. Competitor vs Green Brick inventory and $/sqft (labeled price bases)
2. What moved since the last scrape (adds, price, status, attributes)
3. Current inventory detail
4. Coverage health (healthy / deferred / incomplete) with explicit defer reasons

Dataverse remains the URL registry **and** the active scanning peer list (`gbp_communities` where `scanningallowed=1`). Peer project links (`gbp_gbppeercommunities`) land into `control.web_peer_project` for Peer Arena project stamps. Fabric is the inventory system of record. No competitor write-back to Enterprise Dataverse.

## Naming (three layers)

| Layer | Name |
|---|---|
| Power BI app (human) | Foundation Market Intelligence |
| Report / semantic model (D13) | `report_operations_market_intelligence`, `semantic_model_operations_market_intelligence` |
| Folder | `analytics/operations` |

## Pages

| Page | Primary tables | Audience |
|---|---|---|
| Community Brief | listings + position | Leadership + CI |
| Peer Arena | `competitor_position_obt` + `market_peer_community_obt` + `market_peer_project_obt` + `competitor_price_trend_obt` | CI + Division |
| What Moved | `web_listing_change_det` | Leadership + CI |
| Inventory | `competitor_listing_obt` | CI + Ops |
| Coverage | `web_scrape_coverage_obt` | CI + Ops |

**Filters:** Every page uses the same builder / community / city / side bar. Those slicers bind to `market_dim_builder` and `market_dim_community`, which relate to all fact tables, so a community or builder choice filters Brief, Peer Arena, Moved, Inventory, and Coverage together. After first open, optionally right-click a slicer → Sync slicers across pages in the UI if the service does not auto-group them.

**Peer membership:** A market is competitive when (a) 2+ builders share the community name (`is_multi_builder_market`), (b) the community matches an active scanning Dataverse peer (`is_dataverse_peer` from `gbp_communities` where `scanningallowed=1`, `statecode=0`), or (c) the community matches a peer project link (`is_peer_project` from `gbp_gbppeercommunities` via `control.web_peer_project`). Proximity tiers (`same_community`, `primary` <=3 mi, `secondary` 3 to 5 mi) are **enrichment only**; centroids live in `control.web_community_geo`.

**Peer projects:** Peer Arena includes a slicer on `market_dim_peer_project` (GBP project code / name / OU stamped on peer links). Position rows carry `peer_project_*` when the scrape community matches a peer community (exact or prefix, e.g. `Parks at Wilson Creek` → `Parks at Wilson Creek 60'`).

**GBP benchmark:** Peer Arena includes a disconnected slicer on `market_dim_gbp_benchmark`. Cards show Benchmark ASP / PPSF and Price / PPSF vs the selected GBP community (not auto nearest).

**Peer Arena metrics (scrape-backed):** ASP, $/sqft, inventory and available counts / share, price/PPSF vs community and vs selected GBP benchmark, ranks, price spread, inventory vs plan ASP gap, daily list-price trend, prior-ingest inventory change %, 7-day ASP/inventory WoW when a matching ingest exists, miles to nearest GBP (enrichment), competitive-set scrape coverage %. True absorption requires order/close feeds and is out of scope for website scrape alone.

**Pricing history:** `raw.web_listing_det` is append-only (confirmed Aug 25–Sep 15 2026 snapshots with list/starting price). `competitor_price_trend_obt` rolls that to daily community × builder ASP / PPSF / inventory.

## MVP communities (`source_group`)

See `market_intelligence_mvp.json`. Includes BridgeWater corridor, Legacy Hills, Star Trail, Treeline, Anna Town Square, Parks at Wilson Creek, Village at Midtowne, Whitewing Trails, Wellington, Ribbonwood.

## Price basis (non-negotiable)

| Side | Field | Label |
|---|---|---|
| `competitor_web` / `gbp_web` | Website list / starting | `website_list` |
| `gbp_erp` | SGM `base_revenue` / plan base | `sgm_base_revenue` / `plan_base_price` |

Do not mix bases in one KPI without labels.

## Build and verify

```bash
# Land peer project links (when Ops updates peers / projects)
python3 -u automation/sync_peer_projects.py

# Expand maps + GBP aliases (warehouse control DDL)
# then:
python3 -u automation/build_market_intelligence_report.py
python3 -u automation/run_market_intelligence_mvp_smoke.py
```

Heal MVP gaps:

```bash
python3 -u automation/run_web_scrape_strategic_heal.py \
  --hosts perryhomes.com,ashtonwoods.com,jome.com
# or builder / host filters as needed
```

After scrape landings: `pipeline_operations_analytics_refresh` with `p_domain=operations`, then refresh the Market Intelligence semantic model.

## Power BI app

Target app name: **Foundation Market Intelligence**.  
Publish from Foundation Development for UAT; promote via deployment pipeline to Foundation for production audiences.

Audiences (target):

| Audience | Pages |
|---|---|
| Leadership | Community Brief, What Moved |
| Competitive Intel / Ops | All five pages, including Peer Arena |

App create/update may require a one-time portal publish if the tenant blocks first-time app create via API. Script attempts API update and records the result.

## Acceptance

Source: [`automation/web_scrape/market_intelligence_mvp.json`](../../automation/web_scrape/market_intelligence_mvp.json). The smoke pack `automation/run_market_intelligence_mvp_smoke.py` calls `check` for these eleven tests:

- `mvp_coverage_healthy_or_documented_defer`
- `mvp_map_or_explicit_unmapped`
- `mvp_has_competitor_or_gbp_web_rows`
- `midtowne_has_gbp_erp`
- `change_det_nonempty`
- `price_basis_labeled_in_model`
- `web_community_geo_seeded`
- `proximity_competitive_pairs`
- `position_proximity_metrics`
- `report_and_sm_exist`
- `sm_refresh_completed`

Historical result: **10/11** on 2026-09-17 (proximity checks green; remaining fail is MVP source `stale` coverage, not geo). That result is history. It does not mean the live pack is all green.

## Out of scope for MVP

- Nightly schedules ON
- Full DFW / NHS catalog
- BuilderMetrix bind
- Mortgage / Title blend inside this app
- Market share estimates
- Copilot as a dependency
