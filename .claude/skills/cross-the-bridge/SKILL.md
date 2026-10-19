---
name: cross-the-bridge
description: Design deployment, release and migration safety.
---

# Cross The Bridge

**Disciplines:** Fire, Tools

## Purpose
Design deployment, release and migration safety. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Identify environments, permissions, CI/CD controls and rollback mechanisms.
2. Create promotion gates, migration sequencing and compatibility checks.
3. Validate infrastructure and release commands in nonproduction where permitted.
4. Require explicit approval for production and destructive actions.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
