---
name: guard-the-boundary
description: Review security, privacy and data governance.
---

# Guard The Boundary

**Disciplines:** Tools, People

## Purpose
Review security, privacy and data governance. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Classify data, access paths, secrets, trust boundaries and applicable policies.
2. Identify least privilege, auditability, retention and data movement risks.
3. Require explicit authorization for privileged or destructive operations.
4. Report enforceable controls separately from prompt-only instructions.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
