# Pipelines knowledge

**Documented:** 2026-07-15  
**Scope:** All Fabric DataPipeline items visible to the operator account  
**Method:** live `fab ls` / `fab export` / `fab get` / `fab job run-list` for GBP-Enterprise; Dev confirmed as name-identical twin set

## Inventory summary (Confirmed)

| Location | Pipeline count |
|---|---|
| GBP-Enterprise (prod) | 90 |
| GBP-Enterprise-Dev | 90 (same display names as prod) |
| GitTest | 1 (`Pipeline_1`, id `12a87303-aebe-4629-9c2c-51420b63e502`) |
| All other workspaces | 0 |
| **Total** | **181** |

GitTest `Pipeline_1` is a minimal/test pipeline (not part of the EDW or Salesforce estate).

## Documents in this folder

| File | Contents |
|---|---|
| `gap-register.md` | Formal gap register: 7 items; GAP-01..06 closed in FD 2026-08-12 |
| `orphan-scan.md` | Full orphan scan 2026-08-05: live set (6 of 90), 77 deletable pipelines, non-pipeline orphans, broken schedule findings |
| `catalog-gbp-enterprise.md` | Full prod catalog: ID, activities, schedule, run health, connections |
| `edw-orchestration.md` | EDW dim/fact load families + orchestrator dependency graphs |
| `edw-deep-dive.md` | Stored procs, variant semantics, control tables, gold notes |
| `schedule-truth-table.md` | Active vs expired vs disabled vs Reflex alerts |
| `salesforce-ingestion-prod.md` | Salesforce inbound/outbound/orchestrator deep dive |
| `utilities.md` | Audit, compare, Zonda, web scrape (D19), temp, blocked-logs, view-to-csv, fact hist |
| `data/gbp-enterprise-pipelines.json` | Machine-readable enriched summaries (prod) |
| `data/all-pipelines-index.json` | All 181 pipeline name/id/workspace index |

Lineage diagram: `knowledge/lineage/overview.md`

## How to refresh

```bash
fab ls GBP-Enterprise.Workspace -l
fab export GBP-Enterprise.Workspace/<name>.DataPipeline -o /tmp -f
fab job run-list GBP-Enterprise.Workspace/<name>.DataPipeline
```

## Evidence policy

Confirmed from live Fabric CLI and (for Salesforce) warehouse SQL.  
Inferred only where labeled.
