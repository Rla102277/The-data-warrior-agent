# Foundation current-state inventory

**Baseline commit:** `1e22868cd6f63ef373ebdd517c85009a68ab5007`  
**Branch:** `rebuild/foundation-enterprise-platform`  
**Remote:** `https://dev.azure.com/grbk/Foundation/_git/Foundation`  
**Captured:** 2026-10-16  
**Evidence status:** Confirmed from local Git inspection

## Top-level layout (pre-rebuild)

| Path | Role | Migration stance |
|---|---|---|
| `knowledge/` | Decisions, architecture, ops evidence | Retain; mirror binding decisions into `docs/adr` |
| `dbt/` | dbt project `foundation` | Retain in place (D13) |
| `automation/` | Operational Python/PowerShell scripts | Retain; gradually wrap via Foundation SDK |
| `jobsite/` | Existing Data Engineering Factory | Retain as runtime; rebrand ownership to Foundation (Principle 1) |
| `.cursor/` | Rules, skills, agents, MCP | Retain; extend with Foundation SDK rules |
| `fabric/` | Workspace git reserved (gitignored) | Retain convention |
| `snapshots/` | Local DR exports (gitignored) | Retain |
| `infrastructure/` | Azure infra (e.g. BMX MI) | Retain under `platform/azure` over time |
| `foundation/` | Previously empty placeholder | Becomes Core SDK package |
| `docs/`, `documentation/`, `workspaces/`, `repos/` | Empty shells | Superseded by structured `docs/` |

## Binding decisions present

Confirmed in `knowledge/decisions/README.md`: D0, D1, D4, D5, D6, D7, D8, D9, D10, D12, D13, D14, D15, D16, D17, D18, D19.

Open (must not close independently): D2, D3, D11.

## Uncommitted user work preserved

Preserved on the rebuild branch (not discarded):

- Cursor addons Mac/PowerShell updates
- Jobsite ops doc touch-ups
- `knowledge/operations/foundation-vendor-handoff.md` (untracked)

## Sensitive areas (do not commit)

- `.env`, Key Vault secrets, MCP secret files under `.cursor/secrets/`
- `snapshots/` live exports
- Production schedule enablement artifacts without authorization
