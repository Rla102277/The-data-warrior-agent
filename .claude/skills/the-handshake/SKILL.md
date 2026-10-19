---
name: the-handshake
description: Transfer work between skills without losing context.
---

# The Handshake

**Disciplines:** People, Tools

## Purpose
Transfer work between skills without losing context. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Identify sending and receiving skills, prerequisites, input artifacts, expected output artifacts and acceptance conditions.
2. Verify referenced artifacts exist and are current; distinguish missing evidence from negative results.
3. Record handoff in HANDOFFS.md with ownership, status, blockers and exact next action.
4. Reject handoffs with missing required inputs or insufficient authorization.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
