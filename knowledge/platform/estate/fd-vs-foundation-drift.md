# Foundation Development vs Foundation drift

**Captured:** 2026-10-16  
**Method:** `comm` on sorted `fab ls` outputs (Confirmed)

## Present in Foundation Development only

These items exist in FD and were not listed in Foundation (prod twin):

### Experiments / cleanup candidates

- `Activator 2026-08-20 19:20:19.Reflex`
- `Lots of Samples.SemanticModel`
- `LotsTest.Dashboard`
- `NesLots.SemanticModel`

### BuilderMetrix (D18 — intentional no twin until named)

- `lake_house_buildermetrix` (+ SQLEndpoint)

### Web scrape / market intelligence (D19 — schedule off, no twin until authorized)

- `lake_house_web` (+ SQLEndpoint)
- `notebook_web_listings`, `notebook_web_scrape`
- `pipeline_web_scrape`, `pipeline_web_scrape_heartbeat`
- `semantic_model_operations_market_intelligence` + report
- `semantic_model_operations_competitor_analysis` + report
- `semantic_model_operations_web_listings` + report
- `semantic_model_operations_web_listing_change` + report
- `semantic_model_operations_web_scrape_coverage` + report

### Customer survey VOC + pipeline tooling (FD-only this pass)

- `notebook_operations_customer_survey_voc`
- `pipeline_operations_customer_survey_voc`
- `notebook_pipeline_sync_seed`
- `notebook_pipeline_watermark`

### Other FD-only lakehouse

- `lake_house_pipeline` (+ SQLEndpoint)

## Interpretation

Most missing prod items are **policy-aligned** (D18/D19) or experimental.  
Do not mass-promote. Do clean up sample Lots* and the dated Activator in FD when convenient.

## Shared core (both workspaces)

Stage orchestrator family, Salesforce family, Zonda, warehouse_stage, lake_house_analytics, HBLive/SPLive/BuildPro/dataverse_gbpdev, finance + core operations semantic models/reports, failure activators (named), variable_library_operations.
