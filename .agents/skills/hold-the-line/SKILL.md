---
name: hold-the-line
description: Operate and enforce release quality criteria.
---

# Hold The Line

**Disciplines:** Fire, Practice

## Purpose
Operate and enforce release quality criteria. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Check CI, data quality, security, contract and rollback evidence.
2. Prevent advancement when mandatory checks fail or are unknown.
3. Record approved exceptions with scope, owner and expiry.
4. Publish go/no-go recommendation grounded in evidence.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
