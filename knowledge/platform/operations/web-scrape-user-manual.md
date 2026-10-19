# Web scrape user manual

**Audience:** Operations leaders, competitive intelligence analysts, Power App operators, and Fabric engineers supporting Foundation Development.  
**Workspace:** Foundation Development only. This is not the Operations production workspace.  
**Status:** BETA. On-demand runs proven under Workspace Identity (2026-09-09). Pipeline schedule stays **OFF** until coverage and freshness SLOs are green and you explicitly ask to enable nightly in FD only.  
**Companion docs:** Build and registry detail live in [`web-scrape-setup.md`](web-scrape-setup.md). Apify evaluation lives in [`web-scrape-apify-lab.md`](web-scrape-apify-lab.md). Legacy Power Platform CA stack (leave as-is): [`project-vt-reverse-engineering.md`](project-vt-reverse-engineering.md).

This manual is the operating guide. It is not a DDL reference and it is not a migration plan.

---

## Executive summary (CDO view)

We are building a governed, Foundation-owned competitor listing system so Operations can see what builders are selling, at what price and status, and **what changed** over time.

| Principle | What it means |
|---|---|
| Dataverse is the URL registry | The Power App flags communities and URLs. Foundation reads them. We do not write competitor listings back to Enterprise Dataverse. |
| Fabric is the inventory system of record | Raw JSON, typed warehouse tables, analytics views, and reports all live in Foundation Development. |
| HTML first, browser second | Server HTML adapters run first. Apify runs only when HTML cannot complete the job. |
| Append-only history, current + change layer | Every scrape is kept. Analytics exposes current inventory and change events (adds, price moves, status moves). |
| Controlled spend | Heartbeat detects staleness and content change before re-scraping. Deferrals make incomplete work visible instead of silent failure. |

**Why it matters**

- Competitive visibility for DFW and strategic communities without ad hoc portal checks
- Append-only history plus current and change views for "what moved since last week"
- Controlled browser spend (Apify) only when HTML adapters are not enough

**What "done" looks like for BETA**

Operators open the web listings report, trust current inventory for strategic hosts, and can see adds, removes, price, and status moves without asking engineering to dig through scrape logs.

---

## What questions this system answers

Use the right layer for each question. Do not mix price bases across sides in competitor visuals.

| Question | Where to look |
|---|---|
| What is on the market right now? | `report_operations_web_listings` (Summary / Detail / Map) backed by `analytics.web_listing_obt` |
| What changed since the last scrape? | `analytics.web_listing_change_det` (event types: `added`, `price_changed`, `status_changed`, `attribute_changed`) |
| Is a community stale or blocked? | `analytics.web_scrape_coverage_obt` plus `control.web_scrape_defer_det` |
| How does web inventory compare to GBP ERP? | `report_operations_competitor_analysis` on `analytics.competitor_listing_obt` |
| What did a specific run capture? | Immutable JSON under `lake_house_web` `Files/web/<source_group>/ingest_date=.../` |
| Who flagged this community for scanning? | Enterprise Dataverse `gbp_communities` (read-only shortcut in FD) |

---

## Who does what

| Role | Typical tasks |
|---|---|
| **Power App operator** | Set `gbp_scanningallowed`, listings/plans flags, and URLs on `gbp_communities`. Confirm builder and community names match how Operations talks about the site. |
| **Operations analyst** | Filter the web listings report by community and builder. Use competitor analysis for web vs GBP side-by-side. Treat website list price as `website_list`, not ERP SGM. |
| **Competitive intelligence lead** | Review `web_scrape_coverage_obt` for gaps. Prioritize deferrals and unknown hosts. Decide when a community needs Apify or a new adapter. |
| **Fabric engineer** | Run sync, heartbeat, scrape, analytics refresh. Deploy control DDL. Extend HTML adapters. Run Apify lab cases before promoting AI scraper lanes. |

---

## End-to-end flow

```
Power App (gbp_communities / gbp_brands, Enterprise gbpdev, read-only)
  -> FD dataverse_gbpdev shortcuts
  -> control.sp_sync_web_scrape_from_dataverse
  -> control.web_scrape_source (+ host adapters + heartbeat metadata)
  -> control.sp_refresh_web_scrape_heartbeat
  -> control.sp_seed_web_scrape_queue
  -> scrape (HTML batch and/or notebook_web_scrape with Apify fallback)
  -> warehouse_stage.raw append-only + lake_house_web Files JSON
  -> analytics.web_listing_current / web_listing_change_det / web_scrape_coverage_obt
  -> analytics.web_listing_obt / web_community / web_plan / web_lot
  -> pipeline_operations_analytics_refresh publishes to lake_house_analytics.operations
  -> report_operations_web_listings + report_operations_competitor_analysis
```

**Layers (D13)**

| Layer | Examples | Notes |
|---|---|---|
| Raw files | `Files/web/<source_group>/ingest_date=<date>/<run_id>.json` | Immutable per run |
| Raw typed | `raw.web_listing_det`, `raw.web_page_det`, `raw.web_aggregator_det` | Append-only warehouse tables |
| Control | `control.web_scrape_source`, `_defer_det`, `_heartbeat_det`, `_queue`, `_run_det` | Registry, health, queue |
| Analytics | `web_listing_obt`, `web_listing_current`, `web_listing_change_det`, `web_scrape_coverage_obt` | dbt views in `warehouse_stage.analytics` |
| Presentation | `lake_house_analytics.operations.*` | Copied by analytics refresh pipeline |

Never land typed business tables in `dbo`.

---

## Registry: adding and updating communities

### Primary path (Power App)

1. Open the GBP community registry in **GBP-Enterprise `dataverse_gbpdev`** (Power App).
2. On `gbp_communities`, set:
   - `gbp_scanningallowed = 1`
   - For listings: `gbp_scanlistings = 1` and a non-null `gbp_listingsurl`
   - For plans: `gbp_scanplans = 1` and a non-null `gbp_plansurl`
3. If listings and plans share the same URL, sync creates **one** job.
4. Null URLs are skipped. Sync does not invent aggregator URLs.

Foundation syncs flagged rows into `control.web_scrape_source` with `registry_source = 'dataverse'`. Rows no longer flagged are deactivated. Manual-only rows (GBP homepage, Jome hub, wait_for overrides) are left alone unless a Dataverse URL supersedes them.

### Manual path (exceptions only)

Use manual rows for:

- Green Brick public homepage (`greenbrick-partners`)
- Jome aggregator hub (`jome-bridgewater-midlothian` -> `raw.web_aggregator_det`)
- Builder listing URLs that Dataverse does not yet carry but Operations confirmed live

Example insert pattern (never use `dbo`):

```sql
INSERT INTO control.web_scrape_source
    (source_group, source_name, source_url, scraper, extract_prompt,
     wait_for_text, target_schema, target_table, table_shape,
     create_table_if_missing, files_prefix, is_active, notes,
     community_name, builder_name, registry_source, scrape_mode, listing_url)
VALUES
('example-builder', 'community-a',
 'https://example.com/listings',
 'html_page', NULL, NULL,
 'raw', 'web_listing_det', 'listing', 1,
 'Files/web/example-builder/', 1, 'manual seed; never dbo',
 'Example Community', 'Example Builder', 'manual', 'listing',
 'https://example.com/listings');
```

**Rules**

- `source_group` + `source_name` + `source_url` is the registry grain.
- Listing jobs scrape `listing_url` only. If `listing_url` is null, listing mode skips that builder (no fallback to community homepage).
- Do not set a Jome or Zillow URL as a builder `listing_url`. Aggregators stay in `raw.web_aggregator_det`.

After registry changes, run sync (see [Operator runbook](#operator-runbook)).

---

## Scrape tiers and scrapers

| Tier | Label | When used | Typical scraper |
|---|---|---|---|
| T0 | `t0_html` | Server HTML exposes inventory | `html_page`, `html_extract` |
| T1 | `t1_browser` | JS shell, infinite scroll, Show more | `apify_playwright`, `apify_ai` |
| T2 | `t2_human` | Bot wall, CAPTCHA, login | Defer; escalate to vendor API or proxy |

| Scraper | Role |
|---|---|
| `html_page` | Single GET with browser User-Agent. Used for page-mode and simple pages. |
| `html_extract` | GET plus host-specific adapter (for example `pulte_qmi`, Highland `.homeSpec`, ALH `HomeCard_`). |
| `apify_playwright` | Default browser fallback for JS-heavy hosts. |
| `apify_ai` | Lab-only until scorecard promotion. Not default for strong HTML hosts. |
| `aggregator_fill` | Rows copied from Jome into primary when builder scrape left nulls. |

Host adapters live in `control.web_scrape_adapter` keyed by host name. The notebook inherits adapter, `wait_for_text`, and scraper hints by URL host.

**HTML-capable hosts (confirmed adapters)**

`pulte.com`, `centex.com`, `highlandhomes.com`, `amlegendhomes.com`, `tripointehomes.com`, `jhoustonhomes.com`, `cbjenihomes.com`, `tollbrothers.com`, `coventryhomes.com`, `taylormorrison.com`

**Browser-first hosts (typical deferrals without Apify)**

`perryhomes.com`, `jome.com`, Britton / Perry-family JS shells, unknown hosts with no adapter

---

## Heartbeat, queue, and change detection

The heartbeat process answers: "Should we scrape this source again?"

### Control objects

| Object | Purpose |
|---|---|
| `control.web_scrape_heartbeat_det` | Per-source check: fingerprint, status, queue reason |
| `control.web_scrape_queue` | Pending work seeded for the next scrape pass |
| `control.web_scrape_defer_det` | Explicit log when a source was skipped (unknown host, no Apify, incomplete extract) |
| `control.web_scrape_run_det` | Run summary: jobs succeeded, failed, deferred |

### Stored procedures

| Procedure | Action |
|---|---|
| `control.sp_refresh_web_scrape_heartbeat` | Computes content fingerprint from latest `raw.web_listing_det` snapshot per source. Compares to prior fingerprint and TTL. |
| `control.sp_seed_web_scrape_queue` | Enqueues sources that are stale, changed, or never successfully scraped. |

### Analytics change layer

| View | Grain | Use |
|---|---|---|
| `analytics.web_listing_current` | One row per `listing_key` | Current attributes, `first_seen_at`, `last_seen_at`, `last_change_at`, `is_active` |
| `analytics.web_listing_change_det` | One row per detected change | `change_type`, before/after JSON for price and status |
| `analytics.web_scrape_coverage_obt` | One row per active source | Freshness, listing count, last defer reason, heartbeat status |

**Change event types**

| Type | Meaning |
|---|---|
| `added` | First time this listing identity appeared |
| `price_changed` | `price` or `starting_price` moved |
| `status_changed` | `availability_status` moved |
| `attribute_changed` | Other content hash change (beds, sqft, address, etc.) |

---

## Reports and semantic models

All reports live under **Foundation Development** `analytics/operations`.

| Report | Semantic model | Pages | Primary use |
|---|---|---|---|
| `report_operations_market_intelligence` | `semantic_model_operations_market_intelligence` | Community Brief, Peer Arena, What Moved, Inventory, Coverage | **Product:** Foundation Market Intelligence (MVP app) |
| `report_operations_web_scrape_coverage` | `semantic_model_operations_web_scrape_coverage` | Overview, Gaps | Coverage / completeness / deferrals (strategic filter) |
| `report_operations_web_listing_change` | `semantic_model_operations_web_listing_change` | Overview, Detail | Adds / price / status / attribute change feed |
| `report_operations_web_listings` | `semantic_model_operations_web_listings` | Summary, Detail, Map | Current competitor inventory dump with Avg PPSF |
| `report_operations_competitor_analysis` | `semantic_model_operations_competitor_analysis` | Overview, Community, Plans, Inventory | Web vs GBP ERP side-by-side (component of Market Intelligence) |

Product guide: [`foundation-market-intelligence.md`](foundation-market-intelligence.md). MVP freeze: `automation/web_scrape/market_intelligence_mvp.json`.

**Strategic BETA scope** (must be green first): `automation/web_scrape/strategic_scope.json` (`strategic_rank = 1`).

**Completeness rule** (same as notebook gate): inventory needs identity + price + size; plans need name + price or sqft; source passes when ≥60% of non-collection rows are complete. `coverage_status` values: `healthy`, `empty`, `incomplete`, `deferred`, `stale`, `changed`.

**Open in Fabric (Foundation Development workspace)**

- Coverage: search `report_operations_web_scrape_coverage`
- Web listings: search `report_operations_web_listings`
- Competitor analysis: search `report_operations_competitor_analysis`

Reports read from `lake_house_analytics.operations`. Refresh the semantic model after analytics publish.

### Price basis (competitor analysis)

| Side | Price field | Label |
|---|---|---|
| `competitor_web` / `gbp_web` | Website list / starting price | `website_list` |
| `gbp_erp` inventory | SGM `base_revenue` | `sgm_base_revenue` |
| `gbp_erp` plans | ERP `plan.base_price` | `plan_base_price` |

Do not compare website list price to ERP SGM in the same visual without labeling the basis.

### Zonda-shaped web tables

| Web table | Analog |
|---|---|
| `analytics.web_community` | Zonda community |
| `analytics.web_plan` | Zonda plans |
| `analytics.web_lot` | Zonda lots |

Grain uses `listing_key` as `plan_key` / `lot_key`. Published with operations analytics refresh.

---

## Operator runbook

### A. Standard on-demand refresh (full pipeline)

Use when you want sync, heartbeat, queue seed, and notebook scrape in one Fabric run.

1. Confirm the community is flagged in Dataverse (or manual row is active).
2. In Fabric **Foundation Development**, run `pipeline_web_scrape` on demand.
   - Activities: sync -> heartbeat -> seed queue -> `notebook_web_scrape`
   - Timeout: 12 hours. Per-community errors are isolated.
3. Run `pipeline_operations_analytics_refresh` with `p_domain=operations` (or `all`).
4. Refresh `semantic_model_operations_web_listings` (and competitor SM if needed).
5. Open `report_operations_web_listings`.

Run summary lands in `control.web_scrape_run_det` and `Files/web/runs/`.

### B. Heartbeat and queue only (no scrape)

Use to inspect what would be scraped next without fetching pages.

```bash
python3 -u automation/run_web_scrape_heartbeat.py
```

Review output in `automation/web-scrape-heartbeat-result.json`.

Or run `pipeline_web_scrape_heartbeat` in Fabric (schedule OFF).

### C. HTML-only batch (fast path for adapter hosts)

Use when Apify is not needed or you want a targeted re-scrape by host.

```bash
python3 -u automation/run_web_scrape_html_batch.py
python3 -u automation/run_web_scrape_html_batch.py --hosts pulte.com,centex.com
python3 -u automation/run_web_scrape_html_batch.py --limit 5 --dry-run
```

Then run analytics refresh and report refresh (steps 3-5 in path A).

### D. Process the pending queue

Fans HTML-capable hosts through the HTML batch runner. Marks browser-only hosts as `planned_browser` for notebook / Apify execution.

```bash
python3 -u automation/run_web_scrape_queue.py --strategic-only --html-host-limit 10
python3 -u automation/run_web_scrape_queue.py --html-host-limit 5 --browser-budget 2 --dry-run
python3 -u automation/run_web_scrape_html_batch.py --strategic-only --hosts pulte.com,highlandhomes.com
```

Review `automation/web-scrape-queue-result.json`.

### E. T1 browser (Apify or local Playwright)

Preferred path is Apify Playwright for SPA hosts (Perry, Britton, Jome). If the Apify free plan returns `platform-feature-disabled` / monthly usage hard limit, use local Chromium instead. Do not treat Apify quota failure as an empty community.

```bash
# Apify batch (Perry / Jome / optional Britton) + explicit defer for empty strategic hosts
python3 -u automation/run_web_scrape_apify_batch.py

# Local Chromium fallback when Apify quota is exhausted (Perry Bridgewater)
python3 -u automation/run_web_scrape_local_playwright.py
python3 -u automation/run_web_scrape_local_playwright.py --source-name bridgewater-60

# Ashton Woods community property-card adapter (Legacy Hills; optional --include-parkside)
python3 -u automation/run_web_scrape_ashtonwoods.py

# Self-heal all strategic deferred/stale/empty sources (Playwright harvest + specialized runners)
python3 -u automation/run_web_scrape_strategic_heal.py
python3 -u automation/run_web_scrape_strategic_heal.py --hosts lennar.com,mihomes.com
```

Empty strategic hosts without recoverable inventory get an explicit `defer_reason` such as `empty_page_or_sold_out`, `harvest_empty_retry`, or `incomplete_harvest_retry`. Successful heals clear `defer_reason` and activate `control.web_scrape_adapter` as `local_playwright_cards`. See the coverage report Gaps page.

### F. After registry or DDL changes

```bash
python3 -u automation/deploy_web_scrape_control.py
```

This applies control DDL from `automation/sql/web_scrape_source.sql` and runs Dataverse sync.

---

## 15-minute operations review

Use this cadence when briefing a division or community team on competitor inventory.

1. **Coverage first.** Query or view `analytics.web_scrape_coverage_obt`. Note any source with a defer reason, zero current listings, or heartbeat status indicating staleness.
2. **Current inventory.** Open `report_operations_web_listings`. Filter to the community and builder set you will discuss. Confirm row counts feel plausible vs prior week.
3. **What moved.** For the same community, scan `analytics.web_listing_change_det` for recent `price_changed` and `status_changed` events. Call out new QMI and sold transitions.
4. **Known gaps.** Do not invent inventory for sold-out communities (for example Taylor Morrison SOLD OUT at Phillips Creek Ranch). Leave null price when the builder shows CALL.
5. **Competitor context.** If ERP comparison is in scope, switch to `report_operations_competitor_analysis` and keep price basis labels visible.

---

## Reading coverage and deferrals

### Coverage view (`web_scrape_coverage_obt`)

| Column | How to read it |
|---|---|
| `current_listing_count` | Active rows in `web_listing_current` for this source |
| `last_seen_at` | Latest ingest timestamp for listings from this source |
| `heartbeat_status` | Result of the last heartbeat check |
| `queue_reason` | Why the source was queued (staleness, fingerprint change, never scraped) |
| `last_defer_reason` | Latest skip reason from `web_scrape_defer_det` |
| `scrape_tier` / `strategic_rank` | Priority and expected scraper class |

### Common defer reasons

| Reason pattern | Meaning | Typical fix |
|---|---|---|
| Unknown host | No adapter registered for URL host | Add adapter or route to Apify lab case |
| `jobs_deferred_no_apify` | HTML incomplete and Apify token unavailable in run context | Ensure WI Key Vault access; rerun notebook |
| Incomplete extract | Adapter ran but completeness gate failed | Fix adapter or use browser tier |
| Null `listing_url` | Registry row intentionally has no listing page | Periodic URL probe; set URL when live page appears |

Deferrals are **visible by design**. They are not scrape failures hidden as success.

---

## Aggregators (Jome)

Jome is allowed only as a **secondary fill**, not as the primary listing source.

| Rule | Detail |
|---|---|
| Landing table | `raw.web_aggregator_det` only |
| Fill proc | `control.sp_fill_web_listing_from_aggregator` copies null primary fields from Jome |
| Never overwrite | Non-null builder price, sqft, beds, baths, address, or plan_name stay untouched |
| Match scope | BridgeWater Midlothian builders only for insert; Perry Dallas Bridgewater is not matched to Midlothian |

Confirmed hub: `https://jome.com/master-planned-community/tx/69-bridgewater` (`jome-bridgewater-midlothian`).

First-paint Jome rows (6 homes + 6 plans per builder) are not the full hub claim until Show more clicks stick in browser tier.

---

## Apify lab (before widening AI scraper use)

Do not promote `apify_ai` to default routing without a scorecard win.

1. Cases live in `automation/web_scrape/apify_lab_cases.json` (Perry, Jome, Toll, Pulte benchmark, one unknown DFW host).
2. For each host, run HTML baseline (if any), Apify Playwright, Apify AI Web Scraper.
3. Capture row count, required-field completeness, schema stability across two reruns, elapsed time, Apify cost, retry behavior.
4. Promote AI only when it matches or beats Playwright on completeness and schema stability at acceptable cost.

Full lab protocol: [`web-scrape-apify-lab.md`](web-scrape-apify-lab.md).

---

## Troubleshooting

| Symptom | Likely cause | Action |
|---|---|---|
| Report empty after scrape | Analytics not refreshed | Run `pipeline_operations_analytics_refresh`, refresh SM |
| `web_scrape_coverage_obt` missing | Control DDL not deployed | `python3 -u automation/deploy_web_scrape_control.py`, then `dbt run --select web_scrape_coverage_obt` |
| Pipeline failed on ops sync with `CANNOT_DETERMINE_TYPE` | All-null column in Spark publish path | Fixed in notebook with explicit schema; redeploy notebook via `build_web_scrape.py` |
| Duplicate Highland rows across communities | Same builder slug in different `source_group` | Always filter by `source_group` + `source_name`; skip key is `(source_group, source_name, ingest_date)` |
| Nested `Files/web/Files/web/...` paths | Legacy path bug | `normalize_files_prefix` in shared scrape code; redeploy notebook |
| Jome fill did not add expected rows | Builder/community match rules | Confirm BridgeWater Midlothian naming; check `fill_source = jome` on primary |
| Perry / Britton still zero rows | JS shell needs browser tier | Run Apify path or queue processor with browser budget |

### Useful SQL checks

```sql
-- Latest run summary
SELECT TOP 5 *
FROM control.web_scrape_run_det
ORDER BY started_at DESC;

-- Active sources with deferrals
SELECT source_group, source_name, defer_reason, last_deferred_at
FROM control.web_scrape_source
WHERE is_active = 1 AND defer_reason IS NOT NULL
ORDER BY last_deferred_at DESC;

-- Recent change events
SELECT TOP 50 source_group, builder_name, change_type, detected_at, before_json, after_json
FROM analytics.web_listing_change_det
ORDER BY detected_at DESC;
```

---

## What not to do

- Enable a schedule until coverage/freshness SLOs are green **and** you explicitly ask for FD nightly only. Never enable Enterprise or Foundation prod twin schedules from this manual.
- Write competitor rows back to Dataverse (`gbp_competitorlisting*`, plans, or batch history).
- Scrape aggregators into `web_listing_det` (Jome stays `web_aggregator_det`).
- Invent listing URLs when Dataverse has null.
- Land typed tables in `dbo` (lakehouse or warehouse).
- Put API keys in notebook source (use Key Vault via Workspace Identity).
- Treat first-paint Jome counts as full hub inventory.
- Mix website list price and ERP SGM in competitor visuals without labeling basis.
- Touch Operations, Finance, or GBP-Enterprise production artifacts as part of FD BETA work.

---

## Artifact reference

| Artifact | ID / location |
|---|---|
| Workspace | Foundation Development `40502864-6ece-49b5-807f-6f7c11d1b3e1` |
| Lakehouse (Files) | `lake_house_web` `0b979032-a5d7-4cdb-a6bd-8b2a6964378f` |
| Warehouse | `warehouse_stage` `45471114-769a-4d8f-a0b7-24168e62293c` |
| Notebook | `notebook_web_scrape` `8093b7c6-926a-4fce-bacd-59d73732521c` |
| Pipeline (scrape) | `pipeline_web_scrape` `01a78eb2-c176-4604-88bb-974700cb991d` |
| Pipeline (heartbeat) | `pipeline_web_scrape_heartbeat` `4ce250c8-a3a9-4855-9af8-c8372dd71c25` |
| Coverage report | `report_operations_web_scrape_coverage` `ba0e2122-1842-4491-b9e6-57a8527b50ed` |
| Coverage semantic model | `semantic_model_operations_web_scrape_coverage` `bcd78a3c-ec45-4b82-8f29-0611988e6856` |
| Market Intelligence report | `report_operations_market_intelligence` `0d4b2bd0-74c8-48f4-9140-9e1bb1f49ee9` |
| Market Intelligence semantic model | `semantic_model_operations_market_intelligence` `08ffa8ff-293c-44f5-9bfc-632a661d9085` |
| Strategic scope | `automation/web_scrape/strategic_scope.json` (`strategic_rank = 1`) |
| Market Intelligence MVP freeze | `automation/web_scrape/market_intelligence_mvp.json` |
| Key Vault | `gb-fabric-keyvault` (`apify-api-token` stored; Firecrawl not on critical path) |

**Recreate / deploy scripts**

| Script | Purpose |
|---|---|
| `python3 -u automation/build_web_scrape.py` | Recreate notebook and pipelines |
| `python3 -u automation/deploy_web_scrape_control.py` | Apply control DDL and sync |
| `python3 -u automation/run_web_scrape_heartbeat.py` | Heartbeat + queue refresh (local) |
| `python3 -u automation/run_web_scrape_queue.py --strategic-only` | Process pending queue (BETA set) |
| `python3 -u automation/run_web_scrape_html_batch.py --strategic-only` | HTML-only scrape batch |
| `python3 -u automation/run_web_scrape_apify_batch.py` | T1 Apify batch + strategic deferrals |
| `python3 -u automation/run_web_scrape_local_playwright.py` | Local Playwright when Apify quota is exhausted |
| `python3 -u automation/run_web_scrape_ashtonwoods.py` | Ashton Woods property-card adapter (Legacy Hills) |
| `python3 -u automation/run_web_scrape_strategic_heal.py` | Self-heal strategic deferred/stale/empty sources |
| `python3 -u automation/build_web_listing_change_report.py` | Rebuild listing change-feed report |
| `python3 -u automation/build_web_scrape_coverage_report.py` | Rebuild coverage report |
| `python3 -u automation/build_competitor_analysis_report.py` | Rebuild competitor report |
| `python3 -u automation/build_market_intelligence_report.py` | Rebuild Foundation Market Intelligence SM + report |
| `python3 -u automation/run_market_intelligence_mvp_smoke.py` | MVP acceptance smoke pack |
| `python3 -u automation/publish_market_intelligence_app.py` | Publish/update Power BI app (FD) |

---

## Glossary

| Term | Definition |
|---|---|
| `source_group` | Folder and run grouping (often community slug) |
| `source_name` | Builder or site slug within the group |
| `listing_key` | Stable hash identity for a listing or plan row |
| `content_fingerprint` / `content_hash` | Hash of key listing attributes for change detection |
| `registry_source` | `dataverse` (synced) or `manual` (hand-seeded) |
| `fill_source` | `jome` when aggregator fill supplied all or part of the row |
| `side` (competitor OBT) | `competitor_web`, `gbp_web`, or `gbp_erp` |
| GAP-07 | Workspace Identity Key Vault Secrets User on `gb-fabric-keyvault` (cleared 2026-09-08) |

---

## Related

- Registry and spike history: [`web-scrape-setup.md`](web-scrape-setup.md)
- Apify lab scorecard: [`web-scrape-apify-lab.md`](web-scrape-apify-lab.md)
- HTML-only BETA notes: [`web-scrape-beta-no-kv.md`](web-scrape-beta-no-kv.md)
- Identity / Key Vault: [`identity.md`](identity.md)
- Analytics refresh: [`analytics-setup.md`](analytics-setup.md)
- Zonda analog pattern: [`zonda-setup.md`](zonda-setup.md)
