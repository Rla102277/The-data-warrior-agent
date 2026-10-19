# External repository assessments

Research date: 2026-10-16. Classifications: ADOPT / ADAPT / REFERENCE / REJECT.

Avoid em/en dashes per Foundation deliverable rules.

## microsoft/fabric-cicd

| Field | Assessment |
|---|---|
| Purpose | Code-first Fabric workspace CI/CD |
| Capabilities | Deploy source-controlled Fabric items without raw API scripting |
| Stack | Python, MIT |
| Permissions | Fabric workspace deploy rights |
| Maintenance | Active (pushed 2026-10-15) |
| License | MIT |
| Security risks | Service principal over-privilege if mis-scoped |
| Limitations | Item-type coverage varies; not a substitute for policy gates |
| Reusable | Deployment helpers |
| Integration difficulty | Low |
| Foundation compatibility | High (Phase 7) |
| Decision | **ADOPT** (pinned later after env validation) |

## microsoft/fabric-cli (ms-fabric-cli)

| Field | Assessment |
|---|---|
| Purpose | `fab` filesystem-style Fabric CLI |
| Capabilities | ls/get/import/auth; used already in Foundation ops |
| Stack | Python 3.10-3.13, MIT |
| Decision | **ADOPT** (already in use; pin `ms-fabric-cli`) |

## microsoft/DataFactory.MCP

| Field | Assessment |
|---|---|
| Purpose | MCP server for Azure Data Factory |
| Stack | C# / NuGet `Microsoft.DataFactory.MCP`, MIT |
| Maintenance | Active |
| Decision | **ADAPT** (configure via MCP registry; restrict mutation tools) |

## Light0305/REA (fork of morluto/rea)

| Field | Assessment |
|---|---|
| Purpose | Agent-assisted reverse engineering |
| Risks | Sending proprietary binaries to unapproved providers; license/tool chain sprawl |
| Decision | **REFERENCE** then **ADAPT** behind authorized REA Investigator workflow only; do not vendor wholesale |

## coleam00/ai-software-factory

| Field | Assessment |
|---|---|
| Purpose | Spec/issue driven software factory patterns |
| License | None declared on GitHub metadata |
| Decision | **REFERENCE** (workflow shaping only; Jobsite already covers factory runtime) |

## vaquarkhan/data-engineering-agent-skills

| Field | Assessment |
|---|---|
| Purpose | Data engineering agent skills/workflows |
| License | MIT |
| Decision | **ADAPT** selectively into `skills/` (backfill/replay/quality patterns); do not install entire catalog blindly |

## edkreuk/FMD_FRAMEWORK

| Field | Assessment |
|---|---|
| Purpose | Fabric metadata-driven accelerator |
| License | MIT |
| Decision | **REFERENCE** / selective **ADAPT** for metadata control patterns; Foundation already has stage_load_config and D10 orchestrator model |

## microsoft/dbt-fabric

| Field | Assessment |
|---|---|
| Purpose | dbt adapter for Fabric |
| Decision | **ADOPT** (already required by `dbt/`) |

## erikhoward/adls-mcp-server

| Field | Assessment |
|---|---|
| Purpose | ADLS MCP |
| Decision | **REFERENCE**; prefer Fabric/OneLake paths first (Principle 2) |

## microsoft/mcp / azure-devops-mcp

| Field | Assessment |
|---|---|
| Purpose | Official Microsoft MCP servers |
| Decision | **ADAPT** into Foundation MCP gateway with tool allowlists |

## Preferred dependency set (initial)

1. pydantic, pyyaml, networkx, httpx (SDK core)
2. pytest, ruff, mypy (dev)
3. ms-fabric-cli, fabric-cicd (optional extra `fabric`)
4. dbt-core, dbt-fabric (optional extra `dbt`)
5. sqlglot (optional extra `analysis`)

Do not vendor large upstream repos into Git.
