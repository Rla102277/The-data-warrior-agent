---
name: return-to-the-path
description: Resume interrupted missions from durable evidence.
---

# Return To The Path

**Disciplines:** Practice, Earth

## Purpose
Resume interrupted missions from durable evidence. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Enumerate mission directories and ask which mission only when genuinely ambiguous.
2. Read Battle Map, logs, artifacts, decisions, and repository status; reconcile with current reality.
3. Report last verified checkpoint, unfinished operations, drift, and safe next action.
4. Do not repeat irreversible actions or assert remembered approvals without recorded evidence.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
