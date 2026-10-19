# /the-gate

---
name: the-gate
description: Intake mission, define scope and approve operating authority.
---

# The Gate

**Disciplines:** Earth, People

## Purpose
Intake mission, define scope and approve operating authority. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Identify objective, owner, business outcome, source evidence, constraints, non-goals and acceptance tests.
2. Inspect actual repository and host tool capabilities. Do not assume cloud access.
3. Recommend A Deshi, B Ronin, or C Kensei based on risk and experience; obtain explicit authorization, never self-escalate.
4. Create mission directory, MISSION.md and BATTLE_MAP.json using templates; record approvals and unresolved questions.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
