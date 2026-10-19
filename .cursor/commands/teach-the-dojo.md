# /teach-the-dojo

---
name: teach-the-dojo
description: Improve and maintain the skill system.
---

# Teach The Dojo

**Disciplines:** Practice, People

## Purpose
Improve and maintain the skill system. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Identify recurring failure and create a minimal reproduction.
2. Update the canonical skill and mirrored host definitions together.
3. Add a regression scenario and run structural checks.
4. Record changes, rationale and evidence in CHANGELOG.md without product version labels.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
