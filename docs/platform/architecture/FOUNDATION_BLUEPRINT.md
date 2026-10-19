# Foundation Blueprint

**Status:** Authoritative rebuild architecture for Cursor and automation  
**Repository:** Foundation 2.0 (`git@ssh.dev.azure.com:v3/grbk/Foundation%202.0/Foundation%202.0`)  
**Updated:** 2026-10-16  
**Binding decisions:** [`knowledge/decisions/README.md`](../../knowledge/decisions/README.md)  
**Do not duplicate D-number text here.** Link and enforce in code.

## Objective

An engineer or business product owner describes a data requirement. Foundation discovers relevant systems, applies established architecture, generates a compliant solution, proves correctness, and prepares controlled release.

## Non-negotiable shape

Foundation has **one core engineering framework**. Agents are intelligent **clients** of that framework. Cursor, Azure DevOps, scheduled automation, and any future API/portal must invoke the same SDK surfaces without requiring an LLM.

```text
                 FOUNDATION ENGINEERING EXPERIENCE
                          |
          +---------------+---------------+
          |               |               |
        CURSOR        AUTOMATION       API/PORTAL
          |               |               |
          +---------------+---------------+
                          |
                 FOUNDATION AGENTS (optional intelligence)
                          |
                 FOUNDATION MCP (controlled tools)
                          |
                  FOUNDATION SDK  <--- authoritative
                          |
          +---------------+---------------+
          |               |               |
       METADATA        POLICIES         EVIDENCE
          |               |               |
          +---------------+---------------+
                          |
                FOUNDATION EXECUTION
                          |
               MICROSOFT FABRIC + AZURE
                          |
                 BUSINESS DATA PRODUCTS
```

## Milestone 1 (required before broad agent expansion)

These five components must work together with tests:

| Component | Package / entry | Purpose |
|---|---|---|
| Core SDK | `foundation/` | Typed models, config, evidence, errors |
| Policy engine | `forge.policies` | Deterministic ALLOW / DENY / REQUIRES_APPROVAL |
| Fabric / ADF discovery | `forge.discovery`, `discovery.adf` | Inventory + pipeline IR from fixtures or injected clients |
| Dependency graph | `forge.dependency_graph` | Impact analysis with CONFIRMED / INFERRED evidence |
| Forge CLI | `foundation` / `forge.cli.main` | Doctor, inventory, discover, policy, lineage, validate |

Acceptance: `pip install -e ".[dev]"`, `foundation doctor`, `pytest tests/unit` all succeed. Policies deny unapproved production mutation without an LLM present.

## Binding platform rules (pointers only)

| Topic | Source of truth |
|---|---|
| Decisions D0-D19, open D2/D3/D11 | `knowledge/decisions/README.md` |
| No prod/legacy destruction | `.cursor/rules/no-prod-destroy.mdc` |
| Naming / layers / workspaces | `.cursor/rules/foundation-naming.mdc`, `.cursor/rules/fabric-architect.mdc` |
| Rebuild operating state | `rebuild/EXECUTION_LEDGER.md` |
| Remaining work | `rebuild/IMPLEMENTATION_BACKLOG.md` |
| Agent root rules | `AGENTS.md` |

## Package ownership

| Path | Owns |
|---|---|
| `foundation/` | Stable SDK used by CLI, agents, CI, automation |
| `discovery/` | Parsers and inventory adapters (ADF, dbt, later SQL) |
| `engineering/` | Quality, contracts, reconciliation engines |
| `factory/` | **Forge Line** runtime (Jobsite successor) |
| `platforms/` | Platform profiles (`fabric-first-foundation`, ADF modernization) |
| `automation/` | Operational scripts; gradually call SDK |
| `dbt/` | Project name `foundation` (D13) |
| `rebuild/` | Ledger, backlog, migration evidence |
| `docs/architecture/` | Blueprint and architecture docs |

## Forge Line (Jobsite successor)

**Jobsite is sunset as a separate brand.** Patterns (worktrees, stage gates, FD apply after APPROVE) migrate into Foundation 2.0 `factory/`.

Three planes stay separate:

1. Cursor development-time orchestration (`.cursor/skills/factory`, agents)
2. Forge Line runtime (`factory/` state machine, job folders)
3. Azure/Fabric data pipeline orchestration (D10 metadata-driven execution)

CLI remains `foundation` (never `adef`). Default autonomy Level 2. Default platform profile: `fabric-first-foundation`.

Legacy `jobsite/` in the old Foundation repo remains readable until M11 parity cutover. No new Jobsite features.

## Execution principles

1. **Build, do not scaffold.** No success claim from empty directories or agent role Markdown alone.
2. **Evidence over assumption.** Label CONFIRMED vs INFERRED. Never invent live Fabric/ADF results.
3. **Policy before privilege.** `evaluate_action` gates mutations.
4. **LLM optional.** Specs, policy checks, discovery parses, and tests must run headlessly.
5. **Preserve working behavior.** Factory, dbt, automation, and binding decisions stay until superseded with tests. Jobsite is deprecated in favor of Forge Line.

## First modernization bar (before accepting a modernization agent)

A modernization path is only real when it can:

1. Read a representative pipeline definition.
2. Extract source, target, transform, and dependency metadata.
3. Generate a valid canonical IR.
4. Identify applicable Foundation decisions.
5. Produce a migration assessment with evidence.
6. Generate executable tests for the proposed replacement.

ADF parser + IR + dependency graph + policy hooks are the start of that bar, not the finish.
