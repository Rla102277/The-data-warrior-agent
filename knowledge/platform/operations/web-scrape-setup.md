# Web scrape landing in Foundation

**Created:** 2026-08-25  
**Decision:** D19  
**Status:** Dataverse-driven registry live in Foundation Development.
`control.sp_sync_web_scrape_from_dataverse` MERGEs flagged
`gbp_communities` / `gbp_brands` into `control.web_scrape_source`.
Pipeline sync-then-scrape; schedule OFF until GAP-07 and a successful
on-demand run. Typed rows in `warehouse_stage.raw`, never `dbo`. No
Dataverse writes.

Web data follows the same path as Zonda and Salesforce: **raw files first,
structure second**. Do not scrape when a vendor already has an API (Zonda
already uses that pattern).

`lake_house_web` has no Spark schema support, so Delta `saveAsTable` would
land in lakehouse `dbo`. That is banned. Files stay in the lakehouse. Typed
tables live in `warehouse_stage` under `raw` / `stage` / `control` /
`transform` / `analytics`. Spike leftovers `lake_house_web.dbo.web_page_det`
and `dbo.web_listing_det` were copied into `warehouse_stage.raw` on
2026-08-25; the lakehouse SQL endpoint refused DROP of those dbo tables.
New writes do not go there.

## Control table (add sites here)

Registry: `warehouse_stage.control.web_scrape_source`  
Grain: `(source_group, source_url, source_name)` so one community URL can
list several builders without scraping the same page more than once. `builder_name`
and `community_name` are the display fields. DDL:
`automation/sql/web_scrape_source.sql`. Deploy:
`python3 -u automation/deploy_web_scrape_control.py` (runs
`control.sp_sync_web_scrape_from_dataverse` after DDL).

### Dataverse registry (primary)

The Power App in **GBP-Enterprise `dataverse_gbpdev`** is the URL registry.
Foundation Development has **read-only** lakehouse shortcuts on
`dataverse_gbpdev` for:

| Shortcut | Source | Role |
|---|---|---|
| `gbp_communities` | Enterprise gbpdev | Competitor community list (scan flags + URLs) |
| `gbp_brands` | Enterprise gbpdev | Competitor brand parent for `builder_name` |

Do **not** use `gbp_builder` as the scrape registry. That table is internal
GBP builders (CustSat / ERP), not the competitor URL list.

Scan scope (community must have `gbp_scanningallowed = 1`):

| Job | Flags | URL |
|---|---|---|
| listings | `gbp_scanlistings = 1` | `gbp_listingsurl` not null |
| plans | `gbp_scanplans = 1` | `gbp_plansurl` not null |

If listings and plans share the same URL, sync creates **one** job.
Null URLs are skipped. Sync does not invent aggregator URLs.

`control.sp_sync_web_scrape_from_dataverse` MERGEs flagged rows into
`control.web_scrape_source` with `registry_source = 'dataverse'`, stores
`community_id` / `brand_id` / `job_type`, and deactivates dataverse-sourced
rows that are no longer flagged. Rows with `registry_source = 'manual'`
(GBP homepage, Jome aggregator, wait_for overrides) are left alone except
when a manual listing URL is superseded by the same Dataverse URL (manual
row deactivated).

Host Playwright hints live in `control.web_scrape_adapter` (keyed by host),
not copied onto every community row. The notebook inherits
`adapter` / `wait_for_text` / `scraper` by URL host. Unknown hosts are now
logged to `control.web_scrape_defer_det` and counted as deferred work, not
quietly treated as healthy HTML success.

**Never** INSERT or UPDATE Enterprise Dataverse (`gbp_competitorlisting*`,
`gbp_competitorplans*`, or otherwise). Power App already owns
`gbp_current` / `gbp_batchnumber` history. Deltas vs prior
`ingest_date` or Dataverse current rows are a **later ETL**, not part of
`notebook_web_scrape`. Raw stays append-only.

### Manual registry columns

| Column | Meaning |
|---|---|
| `source_group` | Folder / run group, for example `phillips-creek-ranch` |
| `source_name` | Row slug, for example `highland-homes` |
| `source_url` | Page to scrape |
| `community_name` | Community as listed, for example `Phillips Creek Ranch` |
| `builder_name` | Builder on that community site (`gbp_brands.gbp_name` for dataverse rows) |
| `scraper` | `html_page`, `html_extract`, `apify_ai`, or `apify_playwright` |
| `extract_prompt` | Optional extract instruction |
| `wait_for_text` | Playwright wait text (listing pages); optional when adapter covers host |
| `target_schema` | `raw`, `stage`, `control`, `transform`, or `analytics`. Never `dbo` |
| `target_table` | Table name only (D13 shape marker, no `dim_` / `fact_` / `vw_`) |
| `table_shape` | Template for `create_table_if_missing`: `page`, `listing`, or `json` |
| `scrape_mode` | `page`, `listing`, or `both`. Drives which scrape runs |
| `listing_url` | Builder listing page. If blank, listing mode skips that row |
| `create_table_if_missing` | `1` creates the warehouse table from the shape template |
| `files_prefix` | Lakehouse Files folder, for example `Files/web/greenbrick-partners/` |
| `is_active` | `1` = notebook picks it up |
| `registry_source` | `dataverse` (synced) or `manual` (hand-seeded) |
| `community_id` / `brand_id` | Dataverse ids for later ETL joins |
| `job_type` | `listings` or `plans` for dataverse jobs |
| `notes` | Free text |
| `scrape_tier` | `t0_html`, `t1_browser`, or `t2_human` |
| `strategic_rank` | Lower = higher heartbeat priority |
| `heartbeat_ttl_hours` | Staleness threshold before a source re-enters the queue |
| `last_success_at` / `last_complete_at` | Last successful / complete scrape timestamps |
| `content_fingerprint` | Last successful listing fingerprint |
| `defer_reason` / `last_deferred_at` | Latest reason a source was deferred |

`control.sp_ensure_web_scrape_table` refuses `dbo` and banned prefixes. Fabric
warehouse does not support CHECK constraints, so the procedure (and the
notebook) enforce the schema list.

Add a site and optionally a new table:

```sql
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt,
     wait_for_text, target_schema, target_table, table_shape,
     create_table_if_missing, files_prefix, is_active, notes,
     community_name, builder_name, registry_source)
VALUES
('example-builder', 'community-a',
 'https://example.com/listings',
 'html_page', NULL, NULL,
 'raw', 'example_page_det', 'page', 1,
 'Files/web/example-builder/', 1, 'example; never dbo',
 'Example Community', 'Example Builder', 'manual');
```

Then run `notebook_web_scrape` on demand. `scrape_mode` is `page`, `listing`,
or `both`. Page jobs scrape once per unique URL. Listing jobs scrape
`listing_url` only (community `source_url` is not used as a fallback) into
`raw.web_listing_det` (or `raw.web_aggregator_det` when the control row says
so), then overwrite `lake_house_web` Files
`Files/web/curated/raw/<table>` after each on-demand run (never dbo). Typed
tables stay in `warehouse_stage.raw`. If `listing_url` is null the notebook
skips that builder. Analytics publish is now owned by
`pipeline_operations_analytics_refresh`, which also copies the OBT on its
15-minute cycle.

`pipeline_web_scrape` runs `control.sp_sync_web_scrape_from_dataverse`,
`control.sp_refresh_web_scrape_heartbeat`, `control.sp_seed_web_scrape_queue`,
then `notebook_web_scrape` (12-hour timeout). Per-community errors are
isolated; run summary lands in `control.web_scrape_run_det` and
`Files/web/runs/`. Deferred sources land in `control.web_scrape_defer_det`.

Seeded **manual** rows (kept active unless a Dataverse URL supersedes them):

| Group | scrape_mode | Listing URL | Target |
|---|---|---|---|
| `greenbrick-partners` | page | (homepage) | `raw.web_page_det` |
| `perry-homes-bridgewater` | listing | Perry collection pages | `raw.web_listing_det` |
| `bridgewater-midlothian` | listing | Highland, Tri Pointe, American Legend, John Houston | `raw.web_listing_det` |
| `jome-bridgewater-midlothian` | listing | Jome master-planned hub (no hash) | `raw.web_aggregator_det` |
| `star-trail-prosper` | listing | each builder's own community page | `raw.web_listing_det` |
| `village-at-midtowne` | listing | CB JENI Homes community page | `raw.web_listing_det` |

Star Trail builder listing URLs (community homepage stays `source_url`):

| Builder | listing_url |
|---|---|
| Highland Homes | `https://www.highlandhomes.com/dfw/prosper/star-trail` |
| Coventry Homes | `https://www.coventryhomes.com/new-homes/tx/prosper/star-trail/` |
| American Legend Homes | `https://www.amlegendhomes.com/communities/texas/prosper/star-trail` |
| Britton Homes | `https://www.brittonhomestexas.com/new-homes/texas/dallas/star-trail/star-trail-76` |
| Toll Brothers | `https://www.tollbrothers.com/luxury-homes-for-sale/Texas/Star-Trail` |

Phillips Creek Ranch is largely built out. The only confirmed live builder page as of 2026-08-25 is Taylor Morrison (Darling Homes), title `SOLD OUT`. Other PCR builders stay in the registry with `listing_url` null so the notebook does not fall back to the community homepage. Do not invent aggregator URLs.

Highland BridgeWater (Midlothian) is a different community from Perry Homes Bridgewater. Live listing URL as of 2026-08-25:

`https://www.highlandhomes.com/dfw/midlothian/bridgewater`

Page title `New Homes in BridgeWater`. HTML extract uses `.homeSpec` cards for quick move-in homes and `const availableIfps` for floor plans (Star Trail hyphenated `.home-detail` cards still parse). Completeness skip is `(source_group, source_name, ingest_date)` so Star Trail Highland does not skip this community.

Tri Pointe Homes is also selling at the same Midlothian community. Hub (no ad query string):

`https://www.tripointehomes.com/tx/dallas-fort-worth/bridgewater`

Inventory lives on two collection pages. The notebook uses `sitemap-homes.xml` plus each home's JSON-LD Product (Load More on the page hides plans). Collection listing URLs:

| Collection | listing_url | Homesites |
|---|---|---|
| Discovery (Bridgewater 50s) | `https://www.tripointehomes.com/tx/dallas-fort-worth/discovery-collection-at-bridgewater` | 50 ft |
| Inspiration (Bridgewater 60s) | `https://www.tripointehomes.com/tx/dallas-fort-worth/inspiration-collection-at-bridgewater` | 60 ft |

American Legend Homes community page:

`https://www.amlegendhomes.com/communities/texas/midlothian/bridgewater`

Same `HomeCard_` QMI extract as Star Trail. Confirmed 2026-08-25: 8 inventory rows with address, price, beds, baths, sqft. John Houston Homes community page:

`https://jhoustonhomes.com/community/bridgewater/`

Inventory and floor plans are `jh-spec-card` blocks in the community HTML (no extra sitemap hop). Confirmed 2026-08-25: 8 inventory (5 Available Now with price, 3 Sold with price null) plus 17 plans.

CB JENI Homes The Village at Midtowne (Midlothian) community page. The `#floorplans` hash is an on-page anchor, so listing_url is the community URL:

`https://cbjenihomes.com/communities/the-village-at-midtowne/`

HTML extract uses `home-wrap` cards in `#availableProperties` (QMI) and `#floorplans`. Confirmed live page has 1 Ready Now home (1013 Magdalena Way, Boyd, $289,990) and 1 Boyd floorplan from $296,990.

## Aggregators (secondary only)

Aggregators may land in `raw.web_aggregator_det` only. Do not set a Jome (or
NewHomeSource / Zillow) URL as the `listing_url` for a builder row. Builder
pages stay the source of truth in `raw.web_listing_det`.

After listing jobs, `control.sp_fill_web_listing_from_aggregator` copies into
primary:

- **Update:** same home or plan, primary field is null, aggregator has a
  value. Never overwrite a non-null builder price, sqft, beds, baths,
  address, or plan_name (including Jome "Savings" copy).
- **Insert:** no match in primary for that builder + Midlothian BridgeWater
  + identity. `scraper` is `aggregator_fill`, `fill_source` is `jome`.
  Perry Dallas Bridgewater is not matched to Midlothian.

Match inventory on normalized address (`Ln`/`Lane`, `Trl`/`Trail`). Match
plans on `plan_number` when both have it, else `plan_name`.

`analytics.web_listing_obt` stays a current snapshot of **primary**. Filled
rows show up on the operations report. The full Jome row stays in
`web_aggregator_det` even when primary already has the home.

Jome BridgeWater Midlothian hub (strip `#builders`; that is an on-page
anchor):

`https://jome.com/master-planned-community/tx/69-bridgewater`

Control `source_group` `jome-bridgewater-midlothian`, `source_name` `jome`,
`target_table` `web_aggregator_det`, files `Files/web/jome-bridgewater-midlothian/`.
The extractor fetches the hub, follows every `/community/tx/*bridgewater*midlothian*`
child (five builders as of 2026-08-25), Playwright-clicks Show more homes /
Show more plans on each child, and writes those rows to the aggregator table.
It does not follow `/builder/...` or `/search/new-homes/tx?builder=` (site-wide).
NewHomeSource and Zillow are out of scope for this pass.

Confirmed 2026-08-25 (notebook jobs `91303c83-…`, `5218ebe8-…`, `345ef690-…`):
five child URLs, latest snapshot 6 inventory + 6 plans per builder with price
and sqft (first-paint hrefs). Jome "Show more homes/plans" is React Aria;
Apify Playwright did not grow past that 40s slice. Extra ALH QMI that builder
pages lacked did land: 2237 Wispy Meadow Ln Plan 1459 $444,000 and 4824 Cedar
Bluff Trl Plan 1456 $484,000, inserted into primary as `aggregator_fill`.
Builder prices on matched Wispy Meadow rows were left untouched. Perry Dallas
Bridgewater was not matched. Hub-claimed 91 homes / 14 communities is still
short until Show more clicks stick.

`analytics.web_listing_obt` after fill: 238 current rows (56 with
`fill_source = jome`). Schedule stays OFF.

Website data is also shaped like Zonda (D13 names, never `dbo`):

| Zonda (Enterprise `dbo`) | Foundation web |
|---|---|
| `community` | `analytics.web_community` / `lake_house_analytics.operations.web_community` |
| `plans` | `analytics.web_plan` / `operations.web_plan` (singular; ERP already owns `plan`) |
| `lots` | `analytics.web_lot` / `operations.web_lot` (singular; ERP already owns `lot`) |

Grain: community = builder presence (`source_group` + `source_name` + name);
plan and lot keep `listing_key` as `plan_key` / `lot_key` and join on
`community_key`. `pipeline_operations_analytics_refresh` publishes them with
the rest of operations.

## Lakehouse sync (confirmed)

Notebook job `2faa0b2a-41be-4c12-a837-78b0e9127fe8` finished 2026-08-25 20:24 UTC
and overwrote Files (not dbo) plus `lake_house_analytics.operations.web_listing_obt`.
`analytics.web_listing_obt` is the current snapshot (latest ingest per listing).
Raw history stays in `warehouse_stage.raw.web_listing_det`. Page count rises on
each on-demand run because the Green Brick homepage appends.

| Path | Delta `numRecords` | warehouse_stage count |
|---|---:|---:|
| `Files/web/curated/raw/web_listing_det` | 339 | 339 |
| `Files/web/curated/raw/web_aggregator_det` | 240 | 240 |
| `Files/web/curated/raw/web_page_det` | 14+ | page rows append each GBP run |
| `lake_house_analytics.operations.web_listing_obt` | 238 | 238 (`analytics.web_listing_obt`) |
| `lake_house_analytics.operations.web_community` | 18 | 18 |
| `lake_house_analytics.operations.web_plan` | 141 | 141 |
| `lake_house_analytics.operations.web_lot` | 95 | 95 |
| `lake_house_analytics.operations.competitor_listing_obt` | 275 | 275 |
| `lake_house_analytics.operations.competitor_community_obt` | 11 | 11 |

Immutable per-run JSON still lands under `Files/web/<source_group>/ingest_date=.../`.
An older leftover `Files/tables/raw/...` path is not the curated copy.

Operations report (inventory dump): `report_operations_web_listings` (`79c9e17e-…`)
on `semantic_model_operations_web_listings` (`a5893487-…`) in
`analytics/operations`. Includes Avg PPSF. Import refresh Completed 2026-08-26.

Competitor analysis report: `report_operations_competitor_analysis` (`8079c0ec-…`)
on `semantic_model_operations_competitor_analysis` (`116ecabc-…`). Pages
Overview / Community / Plans / Inventory (1600x900 dual-rail). Rebuild:
`python3 -u automation/build_competitor_analysis_report.py`.

## Competitor analysis (web vs GBP ERP)

Hand map and GBP builder aliases live in warehouse control (never dbo):

| Object | Role |
|---|---|
| `control.web_community_project_map` | Scrape `source_group` + `community_name` → ERP `project_id` |
| `control.web_gbp_builder` | Builder aliases that count as `gbp_web` on the scrape |
| `analytics.competitor_listing_obt` | Listing grain; `side` = `competitor_web` / `gbp_web` / `gbp_erp` |
| `analytics.competitor_community_obt` | Community + side rollup |

Seed DDL: [`automation/sql/web_community_project_map.sql`](../../automation/sql/web_community_project_map.sql).

Confirmed map (2026-08-26): Village at Midtowne → project `00011506`
(CB JENI Midtowne). BridgeWater / Star Trail / Phillips Creek Ranch stay
web-only until an ERP project is confirmed.

**Price basis (do not mix in visuals):**

| Side | Price field |
|---|---|
| `competitor_web` / `gbp_web` | Website list / starting price (`price_basis = website_list`) |
| `gbp_erp` inventory | SGM `base_revenue` (`sgm_base_revenue`) |
| `gbp_erp` plans | ERP `plan.base_price` (`plan_base_price`) |

Scrape deltas and Dataverse `gbp_current` compare stay a later ETL.

## Coverage gaps and fill order

Do not scrape aggregators (NewHomeSource, Zillow) as the **listing** source.
Jome is allowed only as `raw.web_aggregator_det` plus the primary fill proc.
Do not invent homes for sold-out communities.

| Gap | Evidence | Fill with |
|---|---|---|
| Britton Star Trail, 0 rows | JS page (Perry family); HTML extract empty | `perry_family` Apify Playwright: wait for `Sq. Ft.` (25s), XHR JSON first, DOM cards as backup. Skip other builders when today's rows already pass the completeness gate. |
| American Legend missing beds, baths, sqft, address | Card HTML has price and plan only | Parse `HomeCard_title` plus stripped `HomeCard_listItem` (beds, baths, sqft, stories, home URL). Completeness gate skips Apify when those fields land. |
| Highland one home priced CALL | `901 Fallkirk Drive` | Leave null until the builder posts a number. |
| PCR builders with `listing_url` null | 404, city-wide redirect, or empty SPA | Periodic URL probe only (HEAD/GET). If a real community page appears, set `listing_url` and scrape. Until then keep the registry row and skip listing. |
| Darling / Taylor Morrison SOLD OUT | Page title confirmed | One `sold_out` row is enough. Resale is MLS / Zonda, not scrape. |
| `source_name` is builder slug only | PCR Highland would collide with Star Trail Highland | `raw.web_listing_det.source_group` added 2026-08-25. Skip key is `(source_group, source_name, ingest_date)` with a Perry legacy fallback. |
| Community-site collection rows still in the table | Earlier scrape of `startrailprosper.com/builders/` | Keep as history. New runs use builder `listing_url` and builder slug `source_name`. |
| Firecrawl key missing | It used to gate page-mode collection | Removed from the critical path. Page mode is plain HTML fetch; listings stay HTML-first then Apify. |
| Pulte / Centex community pages | Server HTML has `QMIGridCard` inventory + plan links; bare User-Agent gets 404 | Adapter `pulte_qmi` (2026-09-08). Browser UA GET + HTML extract. Proof: Treeline Justin `treeline-211384` (8 QMI + 5 plans). |
| Jome first-paint only (6 homes + 6 plans per builder) | React Aria "Show more homes/plans"; Apify click did not add hrefs | Keep Playwright locators; do not treat first-paint as the 91-home claim. Extra ALH QMI already filled. |

## Proof source (this spike)

| Field | Value |
|---|---|
| Site | Green Brick Partners public homepage |
| URL | `https://www.greenbrickpartners.com/` |
| Why this URL | Company-owned public page; collection is allowed; no page-content API |
| Fields | `source_url`, `page_title`, `status_code`, `markdown`, `run_id`, `ingest_date`, `scraper`, `scrape_ok` |
| Cadence | On demand until first good Dataverse-backed run and GAP-07. Pipeline schedule stays OFF. No Enterprise schedule. No Foundation twin. |
| Scraper | `html_page` (single GET with browser UA) |
| Fallback | None. Keep page-mode URLs explicit in the registry; do not general-crawl |

Apify remains the default toolkit for mixed or unknown sites. This spike is
one public URL, so Firecrawl is the simpler pull.

## Where it lives

| Field | Value |
|---|---|
| Workspace | Foundation Development only |
| Folder | `raw` (lakehouse), `utilities` (notebooks + pipeline) |
| Lakehouse | `lake_house_web` `0b979032-a5d7-4cdb-a6bd-8b2a6964378f` (Files only) |
| Dataverse shortcuts | FD `dataverse_gbpdev` read-only shortcuts to Enterprise gbpdev `gbp_communities`, `gbp_brands` |
| Warehouse | `warehouse_stage` `45471114-769a-4d8f-a0b7-24168e62293c` |
| SQL host | `cx2knzbh2yrejngvheequwseqy-mqufaqgon22utad7n56bdunt4e.datawarehouse.fabric.microsoft.com` |
| Control | `control.web_scrape_source`, `control.web_scrape_adapter`, `control.web_scrape_run_det`, `control.web_scrape_defer_det`, `control.web_scrape_heartbeat_det`, `control.web_scrape_queue` |
| Sync proc | `control.sp_sync_web_scrape_from_dataverse` |
| Typed tables | `raw.web_page_det`, `raw.web_listing_det`, `raw.web_aggregator_det` |
| Zonda-shaped web (dbt) | `analytics.web_community`, `analytics.web_plan`, `analytics.web_lot` |
| Competitor analysis | `analytics.competitor_listing_obt`, `analytics.competitor_community_obt`; control map + GBP builders |
| Current + change | `analytics.web_listing_current`, `analytics.web_listing_change_det`, `analytics.web_scrape_coverage_obt` |
| Notebook | `notebook_web_scrape` `8093b7c6-926a-4fce-bacd-59d73732521c` |
| Listings notebook | `notebook_web_listings` `52dd7d90-da4a-4457-9107-5c60e97beb96` |
| Pipeline | `pipeline_web_scrape` `01a78eb2-c176-4604-88bb-974700cb991d` (sync then scrape; schedule OFF) |
| Heartbeat pipeline | `pipeline_web_scrape_heartbeat` `4ce250c8-a3a9-4855-9af8-c8372dd71c25` (refresh heartbeat + queue only; schedule OFF) |
| Raw grain | `Files/web/<source_group>/ingest_date=<yyyy-mm-dd>/<run_id>.json` (immutable) |
| First run file | `Files/web/greenbrick-partners/ingest_date=2026-08-25/ebbb7835-d8e2-4f34-a23a-75859aa617e3.json` |
| Key Vault | `gb-fabric-keyvault` secrets `firecrawl-api-key` (not stored yet) and `apify-api-token` (stored 2026-08-25) |

Recreate artifacts via `python3 -u automation/build_web_scrape.py` (sets
`format=ipynb` on the notebook; without that Fabric returns
`PyToIPynbFailure`). Deploy or refresh the control plane with
`python3 -u automation/deploy_web_scrape_control.py`.

FD workspace identity has **Key Vault Secrets User** on `gb-fabric-keyvault`
and **Storage Blob Data Contributor** on `gbpintegrationfiles` (GAP-07 cleared
2026-09-08 via `bash automation/grant_wi_rbac.sh`). Confirmed 2026-09-09:
on-demand `pipeline_web_scrape` **Completed** under WI (~14 min; run
`3e34a015-…`, `jobs_failed=0`, `rows_written=314`). First attempt that day
failed at ops lakehouse sync with Spark `CANNOT_DETERMINE_TYPE` (all-null
column inference); fixed in `notebook_web_scrape` with an explicit schema and
run summary before ops sync. Schedule stays **OFF** until you explicitly ask
to enable nightly in Foundation Development only. Do not enable Enterprise or
the Foundation prod twin.

## Intended path

```
Power App gbp_communities / gbp_brands (Enterprise gbpdev, read-only)
  -> FD dataverse_gbpdev shortcuts
  -> control.sp_sync_web_scrape_from_dataverse
  -> control.web_scrape_source (+ host adapters + heartbeat metadata)
  -> control.sp_refresh_web_scrape_heartbeat
  -> control.sp_seed_web_scrape_queue
  -> notebook_web_scrape (HTML then Apify; Jome -> web_aggregator_det)
  -> warehouse_stage.raw append-only
  -> analytics.web_listing_current / web_listing_change_det / web_scrape_coverage_obt
  -> analytics.web_listing_obt / web_community / web_plan / web_lot
  -> (later ETL only if explicitly approved) Dataverse gbp_current compare or write-back
```

| Need | Service | Lands as |
|---|---|---|
| Public / docs / listings | HTML adapters first, then Apify | JSON in Files |
| SPA / infinite scroll | Apify (browser actor) | JSON dataset |
| Bot wall / CAPTCHA | Bright Data or Oxylabs | JSON |
| Login portal | Apify with stored session, or ask vendor for API | JSON |
| Vendor already has API | Skip scrape | Direct REST into raw |

Do not start with homegrown Playwright on a VM, Fabric Copy HTTP, or Power
Query web scrape.

## Do not

- Enable a schedule until a successful on-demand Dataverse-backed run **and**
  GAP-07 (FD WI is Key Vault Secrets User). Then enable only in Foundation
  Development. Never Enterprise or the Foundation prod twin.
- Write competitor rows back to Dataverse (`gbp_competitorlisting*`, plans, etc.)
- Rebuild Power App `gbp_current` / `gbp_batchnumber` history in the notebook
- Scrape aggregators into `web_listing_det` (Jome stays `web_aggregator_det`)
- Invent listing URLs when Dataverse has null
- Write typed tables to `dbo` (lakehouse or warehouse)
- Promote to Foundation until FD has a named source list and a successful
  Firecrawl (or Apify) run
- Add a new web-scrape dbt model until another consumption subject is named. The named model `semantic_model_operations_market_intelligence` (report `report_operations_market_intelligence`) allows the existing Market Intelligence views (`competitor_listing_obt`, `competitor_community_obt`, `web_listing_change_det`, `web_scrape_coverage_obt`, `competitor_position_obt`, `competitor_price_trend_obt`, `community_proximity_map`, `competitor_peer_obt`, `market_dim_builder`, `market_dim_community`). Schedules stay off. No Foundation twin.
- Scrape sites Green Brick is not allowed to collect
- Put keys in notebook source
- Touch Enterprise / Operations / Finance as part of this standup

## Perry Homes Bridgewater spike (2026-08-25)

Public collection pages (competitor inventory, public HTML):

- `https://www.perryhomes.com/new-homes/texas/dallas/bridgewater/bridgewater-60`
- `https://www.perryhomes.com/new-homes/texas/dallas/bridgewater/bridgewater-70-80`

Apify AI Web Scraper trial requires an Apify login; no token was in the
environment. Listings were pulled from the rendered pages, then landed as
JSON under `Files/web/perry-homes-bridgewater/` and
`warehouse_stage.raw.web_listing_det` (52 unique rows: 15 inventory, 37
plans). Notebook `notebook_web_listings`. Schedule OFF. No dbt model.

Apify token later stored as `apify-api-token`. Actor `apify/ai-web-scraper`
run `dUEe3mXvsARtez1hR` succeeded but returned empty listing arrays (page
shell only; inventory is JS-rendered). Follow-up `apify/playwright-scraper`
run `B1ttbH9GqutkAhxjm` waited for `Sq. Ft.` and extracted the same 52
unique rows, landed as
`Files/web/perry-homes-bridgewater/ingest_date=2026-08-25/apify-playwright-0cb287dd-4978-455d-bacf-0fe26b8842b6.json`.

## Related

- Zonda analog: [`zonda-setup.md`](zonda-setup.md)
- Identity / GAP-07: [`identity.md`](identity.md)
- Recreate: `python3 -u automation/build_web_scrape.py`
- Control deploy: `python3 -u automation/deploy_web_scrape_control.py`
