# /forge-a-contract

---
name: forge-a-contract
description: Specify executable data contracts and ownership.
---

# Forge A Contract

**Disciplines:** Earth, Tools

## Purpose
Specify executable data contracts and ownership. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Identify source, consumer, owner, data semantics, keys, nullability and freshness SLOs.
2. Define schema, invariants, allowed evolution, privacy classification and error handling.
3. Produce contract artifact and representative valid/invalid fixtures.
4. Implement or recommend runnable contract checks in target stack.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
