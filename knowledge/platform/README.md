# Foundation knowledge base

**Owner posture:** CTO / Head of Data & Integration  
**Repo:** Foundation 2.0 (analytics build + engineering factory)  
**Last live Fabric refresh:** 2026-10-16  
**Legacy port:** see [`LEGACY_PORT.md`](LEGACY_PORT.md)

Evidence policy: label **Confirmed** (live command/MCP) vs **Inferred** vs **Legacy-sourced** (copied from ADO Foundation repo).

## Start here (priority order)

| Doc | Purpose |
|---|---|
| [`estate/lead-assessment.md`](estate/lead-assessment.md) | Live inheritance brief |
| [`LEGACY_PORT.md`](LEGACY_PORT.md) | What we pulled from legacy and what we refused |
| [`decisions/README.md`](decisions/README.md) | Binding D0–D19 |
| [`rebuild-plan/rearchitecture.md`](rebuild-plan/rearchitecture.md) | Rebuild intent |
| [`analytics/gold-to-dbt-map.md`](analytics/gold-to-dbt-map.md) | Consumption mapping |
| [`analytics/presentation-subjects.md`](analytics/presentation-subjects.md) | Presentation subjects |
| [`lineage/orchestrator-e2e.md`](lineage/orchestrator-e2e.md) | Stage orchestrator path |
| [`pipelines/README.md`](pipelines/README.md) | Pipeline knowledge index |
| [`operations/analytics-setup.md`](operations/analytics-setup.md) | Analytics engineer setup |
| [`operations/hydration-runbook.md`](operations/hydration-runbook.md) | Data hydration |
| [`operations/ACTIVE.md`](operations/ACTIVE.md) | Active ops pointer (legacy) |

## Live estate (this session)

| Doc | Purpose |
|---|---|
| [`estate/workspaces.md`](estate/workspaces.md) | Fabric workspaces |
| [`estate/data-map.md`](estate/data-map.md) | FD tables/schemas |
| [`estate/azure.md`](estate/azure.md) | Subscriptions / capacity |
| [`estate/ado.md`](estate/ado.md) | ADO projects |
| [`estate/fd-vs-foundation-drift.md`](estate/fd-vs-foundation-drift.md) | Dev vs prod twin |
| [`operations/access-gaps.md`](operations/access-gaps.md) | RBAC / MCP holes |
| [`inventory/`](inventory/) | Raw `fab` dumps |

## Code that owns analytics (in this repo)

| Path | Role |
|---|---|
| `dbt/` | dbt project `foundation` (ported) |
| `automation/sql/` | Control + transform + analytics SQL (ported) |
| `foundation/` | SDK, policy, discovery (native F2.0) |
| `factory/` | Forge Line (native F2.0) |

## Conflict rule

If **live estate** docs disagree with **legacy-sourced** docs, **live wins**. Update legacy-sourced files or mark them superseded; do not silently follow stale Markdown.
