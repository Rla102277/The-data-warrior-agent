# /guard-the-forge

---
name: guard-the-forge
description: Discover and bound actual tool capabilities.
---

# Guard The Forge

**Disciplines:** Tools, Void

## Purpose
Discover and bound actual tool capabilities. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Inventory available filesystem, terminal, Git, cloud, MCP and deployment capabilities with evidence.
2. Classify read, write, destructive, external and privileged actions.
3. Map actual host permission enforcement separately from instruction-level autonomy.
4. Block unsafe execution when authorization or required tools are missing.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
