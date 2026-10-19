---
name: the-sentinel
description: Apply mission quality and policy gates.
---

# The Sentinel

**Disciplines:** Fire, Practice

## Purpose
Apply mission quality and policy gates. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Read acceptance criteria, mission authority, risk register, evidence, and tests.
2. Verify observed outputs and actual command exit codes, not claimed success.
3. Block on unresolved critical security risks, failed tests, unauthorized actions, or missing mandatory evidence.
4. Write GATES.md with pass/fail/unknown, rationale and remediation. Unknown is never pass.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
