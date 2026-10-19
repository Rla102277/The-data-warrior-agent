# /walk-the-path

---
name: walk-the-path
description: Execute a plan with checkpoints and dependency tracking.
---

# Walk The Path

**Disciplines:** Fire, Practice

## Purpose
Execute a plan with checkpoints and dependency tracking. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Read approved plan, active Battle Map and authority.
2. Work in dependency order; verify each milestone before continuing.
3. Update evidence and blockers after every material action.
4. Stop at decision points, scope changes or failed quality gates.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
