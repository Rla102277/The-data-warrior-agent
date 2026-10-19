---
name: the-challenge
description: Interrogate assumptions one question at a time.
---

# The Challenge

**Disciplines:** Earth, Void

## Purpose
Interrogate assumptions one question at a time. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Restate the objective and locate its weakest consequential assumption.
2. Ask exactly ONE precise question per turn; wait for the user's answer.
3. Probe counterexamples, failure modes, data ownership, scale, risk, semantics and observable success.
4. Record confirmed answers separately from assumptions; do not invent responses.
5. Conclude with a concise challenged specification and unresolved risks only when the user requests conclusion or the ambiguity is resolved.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
