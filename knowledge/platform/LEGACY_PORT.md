# Legacy Foundation → Foundation 2.0 port log

**CTO decision date:** 2026-10-16  
**Source:** `~/Documents/Projects/Foundation` (ADO project **Foundation**)  
**Destination:** Foundation 2.0 (this repo)  
**Rule:** Bring **only** what the analytics build needs and what F2.0 was missing. Do not clone the whole legacy tree.

## Ported (Confirmed)

| Asset | Why |
|---|---|
| `dbt/` (models, macros, tests, project yml; no packages/target/logs) | Consumption layer is the analytics product. F2.0 had zero dbt. |
| `automation/sql/` | Live control + transform + analytics SQL that backs FD (`stage_load_config`, procs, views). |
| `knowledge/analytics/` | Gold→dbt map, presentation subjects. |
| `knowledge/rebuild-plan/` | Rearchitecture, rename map, orchestrator rebuild, EDW D13 eval. |
| `knowledge/lineage/` | Orchestrator E2E and lineage overview. |
| `knowledge/pipelines/` | Legacy + Salesforce pipeline catalog, gap register, schedule truth. |
| `knowledge/architecture/` | Prior architecture narrative. |
| `knowledge/external-rfs/` | RFI/RFP/RFS scope for integration strategy. |
| `knowledge/workspace-map/` | Historical workspace map. |
| `knowledge/inventory/environment-legacy.md` | Prior env doc (keep beside live 2026-10-16 inventory). |
| `knowledge/operations/*` (selected) | Analytics setup, hydration, deployment, CustSat/VOC specs, Zonda, web scrape, BMX setup, governance, market intel. |
| `knowledge/operations/bmx-mi-phase1/` | Spec/params/handoff only. |
| `docs/standards/` | If present from legacy standards tree. |

## Explicitly rejected (do not port)

| Asset | Why rejected |
|---|---|
| Entire `jobsite/` | Sunset; F2.0 Factory supersedes. |
| Duplicate `foundation/` SDK | F2.0 already owns SDK/policies/CLI. |
| `snapshots/` and `fabric/foundation-development` exports | Large; remain in legacy checkout; refresh live via `fab`. |
| `knowledge/operations/bmx-mi-phase1-2026-09-29/**` JSON dump forest | Ops incident forensics, not analytics model source of truth. |
| Cursor/MCP enablement packs (Graph, Planner, Entra, ROI drafts) | Not analytics build. |
| Jobsite how-to / summary ops docs | Brand sunset; see F2.0 factory skill. |
| Unrelated `automation/mcp_*` (Rubrik, ArcticWolf, Freshservice, …) | Outside data platform scope for this repo. |
| `dbt/dbt_packages`, `dbt/target`, `dbt/logs` | Regenerable; keep out of git. |
| `dbt/profiles.yml` | Local; use `profiles.yml.example`. |

## Still lives only in legacy (by design for now)

- Full snapshot history under `Foundation/snapshots/`
- BMX MI phase1 evidence JSON
- Jobsite runtime
- Cursor addons packaging scripts

Point engineers needing those at the legacy Foundation checkout or ADO **Foundation** project. Do not pretend F2.0 is a full historical archive.

## After this port

1. Prefer **live** `knowledge/estate/*` and `knowledge/inventory/fab-*` over stale workspace-map when they disagree.
2. Prefer **decisions/README.md** in this repo (already present) as binding D-numbers.
3. dbt compile/run still requires Fabric ODBC + `profiles.yml` from example (not done in this port).
