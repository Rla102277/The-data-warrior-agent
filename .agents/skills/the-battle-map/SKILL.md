---
name: the-battle-map
description: Maintain machine-readable and human-readable mission state.
---

# The Battle Map

**Disciplines:** Practice, Earth

## Purpose
Maintain machine-readable and human-readable mission state. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Read BATTLE_MAP.json and MISSION.md; reconcile status with actual files and tests.
2. Record objective, active phase, tasks, dependencies, authority, blockers, decisions, evidence paths, and next action.
3. Use atomic file updates where possible; avoid fabricated completion states.
4. Update only after observing results; unresolved tests remain pending.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
