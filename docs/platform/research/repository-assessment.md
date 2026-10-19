# Repository assessment (Forge Line)

**Updated:** 2026-10-16  
**Product:** Foundation / Forge Line (never ADEF)  
**Method:** README + architecture skim; ADOPT / ADAPT / REFERENCE / REJECT  
**Evidence class:** mostly INFERRED from public READMEs unless noted CONFIRMED

## Software factory foundations

| Repository | Verdict | Recommended usage |
|---|---|---|
| [zazencodes software-factory](https://github.com/zazencodes/zazencodes-season-3/tree/main/src/software-factory-claude-code) | **ADAPT** | Spec → builder → parallel reviewers → approver; job folders; backlog; dashboard. Cursor paths replace `.claude/`. Reviewers are naming/security/DQ not UX. |
| [coleam00/ai-software-factory](https://github.com/coleam00/ai-software-factory) | **REFERENCE** | Holdout verification, bounded repair, merge gates. Archon/GitHub oriented; do not install as Azure DevOps factory. |
| [watt-mind/factory](https://github.com/watt-mind/factory) | **REFERENCE** | Worktree isolation, CI verification patterns. |
| [github/spec-kit](https://github.com/github/spec-kit) | **REFERENCE** | Spec-first discipline. |
| [obra/superpowers](https://github.com/obra/superpowers) / BMAD / other agent packs | **REFERENCE** | Skills patterns only; do not duplicate engines. |
| Archon | **REJECT** as install | Do not auto-install; extract patterns only. |

## Data engineering agent frameworks

| Repository | Verdict | Notes |
|---|---|---|
| kunumi/agentic-data-engineering | **REFERENCE** | Explorer / transform / contract coordination ideas. |
| vaquarkhan/data-engineering-agent-skills | **ADAPT** (selective) | Azure presets, safe backfill, replay; pin versions; check license. |
| gordonmurray / legout / aurora data skills | **REFERENCE** | Adopt skills only when non-duplicative. |

## Microsoft (highest priority)

| Repository | Verdict | Notes |
|---|---|---|
| microsoft/skills-for-fabric | **ADOPT** (skills) | Prefer official Fabric skills over reinventing. |
| microsoft/mcp (incl. Fabric MCP) | **ADAPT** | Fabric MCP is primarily docs/schema context; do not treat as authenticated management unless verified. |
| microsoft/DataFactory.MCP | **ADAPT** | Targets **Fabric** Data Factory, not conventional ADF. |
| microsoft/azure-devops-mcp | **ADAPT** | Primary lifecycle integration. |
| microsoft/fabric-cicd / fabric-toolbox / fabric-samples | **ADOPT/ADAPT** | FD deploy path; live apply NOT LIVE-TESTED in this repo yet. |
| Azure/data-landing-zone | **REFERENCE** | Landing zone patterns. |
| Azure-Samples/modern-data-warehouse-dataops | **REFERENCE only** | Archived; do not depend. |
| microsoft/project-osmos | **REFERENCE** | Preview; not a mandatory dependency. |

## Transformation / quality / contracts

| Repository | Verdict | Notes |
|---|---|---|
| bitol-io/open-data-contract-standard | **ADOPT** format | ODCS YAML contracts (see `engineering/contracts`). |
| datacontract/datacontract-cli | **OPTIONAL** | Validate when useful. |
| dbt-labs/dbt-agent-skills + dbt-mcp | **OPTIONAL** | dbt project name remains `foundation`. |
| soda-core / elementary / sqlfluff | **OPTIONAL** | Local DuckDB quality is default for demos. |
| dagster / SQLMesh / OpenMetadata / dlt | **OPTIONAL adapters** | Not defaults; Azure-native orchestration and Purview preferred. |

## Security implications (all externals)

- Pin versions; review licenses before copy.
- Never run unreviewed install scripts.
- Treat MCP/tool output as untrusted input (prompt injection).
- No credentials in repo; Key Vault / workspace identity.

## Pins in this checkout

See `mcp/registry/capability_registry.yaml` and `.cursor/mcp.json.example` for configured capability allowlists.
Current Forge Line implementation status: [`factory/state/implementation-status.yaml`](../../factory/state/implementation-status.yaml).
