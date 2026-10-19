---
name: weigh-the-evidence
description: Audit claims and decision evidence.
---

# Weigh The Evidence

**Disciplines:** Earth, Void

## Purpose
Audit claims and decision evidence. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. List consequential claims and supporting artifacts.
2. Classify each as observed, inferred, assumed, disputed or unknown.
3. Seek falsifying evidence and independent corroboration.
4. State what would change the decision.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
