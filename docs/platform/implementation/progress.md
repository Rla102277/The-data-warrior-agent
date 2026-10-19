# Forge Line progress

**Updated:** 2026-10-16  
**Status file:** [`factory/state/implementation-status.yaml`](../../factory/state/implementation-status.yaml)

## Completed (CONFIRMED)

| Milestone | Evidence |
|---|---|
| M0 Birth | Commit `46488e2` pushed to ADO via HTTPS+az; Factory declared Jobsite successor |
| M1 Kernel | `pytest tests/unit` 54 passed; `foundation doctor` ok; LLM not required |
| M2 Modernization | `foundation modernize` on ADF fixture; cutover DENY without approval |
| M3 Factory runtime | Persistent `JobStore` + workflow transitions + bounded repair |
| M4 Cursor loop | `.cursor/skills/factory` + thin agents |
| M5 Control map | `control/ingestion_map.py`; parallel DB forbidden |
| M6 Quality/ODCS | Contract ops + DuckDB/fallback reconciliation |
| M7 MCP gateway | Registry + authorize_tool; DataFactory.MCP labeled Fabric DF |
| M8 Local demo | `forge job demo` PASSED independent fixtures |
| M9 Dashboard | `factory/dashboard.html` reads real `board.json` |
| M10 CI/CD | ADO pipelines + Bicep skeleton; live fab NOT LIVE-TESTED |
| M11 Jobsite sunset | `docs/operations/jobsite-sunset.md`; bridge points to successor |

## Session wave (2026-10-16 later)

| Change | Evidence |
|---|---|
| Restored accidental WIP strip of factory/modernize CLI | `pytest` green again |
| `forge job approve` / `rework` | CLI + workflow transitions + unit tests |
| Research assessment | `docs/research/repository-assessment.md` |
| ADEF directive remapped | Plan + identity: Forge Line only |
| Live estate knowledge base | `knowledge/` from `fab`/`az`/ADO MCP (see `knowledge/estate/lead-assessment.md`) |

## Known gaps (honest)

- Live Fabric `fab` / `fabric-cicd` apply: NOT LIVE-TESTED
- Legacy Foundation repo Jobsite docs redirect: manual follow-up
- SSH git push still needs ADO SSH key; HTTPS+az works
- FastAPI/Next.js control plane: deferred (HTML dashboard sufficient for now)
