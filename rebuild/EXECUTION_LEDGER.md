# Foundation 2.0 execution ledger

**Repository:** `git@ssh.dev.azure.com:v3/grbk/Foundation%202.0/Foundation%202.0`  
**Local path:** `/Users/randy/Documents/Projects/Foundation-2.0`  
**Updated:** 2026-10-16  
**Blueprint:** [`docs/architecture/FOUNDATION_BLUEPRINT.md`](../docs/architecture/FOUNDATION_BLUEPRINT.md)  
**Backlog:** [`IMPLEMENTATION_BACKLOG.md`](IMPLEMENTATION_BACKLOG.md)  
**Factory status:** [`factory/state/implementation-status.yaml`](../factory/state/implementation-status.yaml)

## Product identity

| Fact | Value |
|---|---|
| Product | Foundation |
| Factory | Forge Line (Jobsite successor) |
| CLI | `foundation` (never `adef`) |
| Default autonomy | Level 2 |
| Default profile | `fabric-first-foundation` |

## Jobsite sunset

| Fact | Status |
|---|---|
| Intent | Complete in Foundation 2.0 |
| Successor | `factory/` runtime + Cursor `/factory` skill |
| Legacy jobsite | Read-only in old Foundation checkout |
| Dual runtime | Bridge only (`forge.jobsite_bridge`) |

## Milestone tracker

| Milestone | Goal | Status |
|---|---|---|
| M0 | Birth + Factory declaration | PASSED |
| M1 | SDK kernel gate | PASSED |
| M2 | ADF modernization slice | PASSED |
| M3 | Factory runtime | PASSED |
| M4 | Cursor /factory loop | PASSED |
| M5 | Control / D10 mapping | PASSED |
| M6 | Quality + ODCS | PASSED |
| M7 | MCP gateway | PASSED |
| M8 | Local synthetic demo | PASSED |
| M9 | Dashboard | PASSED |
| M10 | ADO + fabric-cicd path | PASSED (live fab NOT LIVE-TESTED) |
| M11 | Jobsite sunset docs | PASSED |

## Tests executed in this repo (Confirmed)

```text
python3 -m pip install -e ".[dev,local]"
python3 -m pytest tests/unit -q --tb=short
.........................................................                [100%]
57 passed
ruff check foundation discovery engineering control factory demos mcp tests -> All checks passed
foundation doctor -> status ok
forge job demo -> status passed (independent aggregates)
```

## Post-M11 wave (Confirmed)

- Restored factory/modernize CLI after accidental working-tree deletion
- `forge job approve|rework` wired to `WorkflowEngine` with D12 prod gate
- `docs/research/repository-assessment.md` (ADEF refs remapped to Forge Line)

## Push evidence

- Initial seed commit pushed to `main` via HTTPS + Azure AD token (SSH key not registered).
- Post-M11 approve/rework wave committed on main.
