# /forge-the-skill

---
name: forge-the-skill
description: Create composable host-native engineering skills.
---

# Forge The Skill

**Disciplines:** Practice, Tools

## Purpose
Create composable host-native engineering skills. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Define trigger, purpose, prerequisites, inputs, outputs and failure modes.
2. Write a self-contained SKILL.md that uses host tools and never requires a custom LLM server.
3. Add Cursor and Claude equivalents plus a behavioral scenario.
4. Test invocation and revise based on observed failure.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
