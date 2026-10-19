# Jobsite sunset

**Status:** IN_PROGRESS → complete when M11 acceptance passes  
**Successor:** Forge Line (`factory/` in Foundation 2.0)

## What moved

| Jobsite concept | Forge Line location |
|---|---|
| Orchestrator loop | `.cursor/skills/factory/SKILL.md` + `forge.line.WorkflowEngine` |
| Job state | `factory/jobs/<id>/job.json` |
| Worktrees / branches | `factory/<job-id>` branch naming retained |
| Dashboard | `factory/dashboard.html` + `factory/board.json` |
| Policy / naming | `forge.policies` (single source) |
| CLI | `forge job ...` (not `jobsite`, not `adef`) |

## Rules

1. No new features in legacy `jobsite/` (old Foundation repo).
2. One factory runtime only after cutover.
3. FD Fabric apply still requires machine policy APPROVE + D12.
4. Approver may merge engineering `main`; never auto-merge production Fabric.

## Bridge

`forge.jobsite_bridge.jobsite_bridge_status()` reports absorption until legacy references are removed.

## Acceptance (M11)

- [x] Forge Line runtime present and tested
- [x] Cursor `/factory` skill and thin agents present
- [x] Jobsite documented as deprecated
- [x] Dual-brand language removed from Blueprint package table
- [ ] Legacy Foundation repo docs redirected (manual follow-up in old checkout)
