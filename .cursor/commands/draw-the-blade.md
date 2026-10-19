# /draw-the-blade

---
name: draw-the-blade
description: Implement authorized engineering changes.
---

# Draw The Blade

**Disciplines:** Fire, Tools

## Purpose
Implement authorized engineering changes. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Confirm mission authority, scope and acceptance criteria.
2. Inspect target code and tests; propose smallest viable change.
3. Make edits using host-native tools and record touched files.
4. Run relevant tests and show actual results; stop at failing gates.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
