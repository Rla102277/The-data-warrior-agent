---
name: face-the-failure
description: Respond to incidents and engineering failures.
---

# Face The Failure

**Disciplines:** Fire, People

## Purpose
Respond to incidents and engineering failures. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Establish impact, severity, current evidence and containment authority.
2. Prefer reversible containment; require approval for destructive changes.
3. Gather logs and timeline, isolate hypotheses and test carefully.
4. Document recovery verification, root cause confidence and follow-up controls.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
