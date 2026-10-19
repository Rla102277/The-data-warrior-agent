# /test-the-steel

---
name: test-the-steel
description: Execute tests and prove engineering correctness.
---

# Test The Steel

**Disciplines:** Fire, Practice

## Purpose
Execute tests and prove engineering correctness. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Inspect acceptance criteria and existing test framework before adding tests.
2. Test happy path, duplicates, retries, late arrival, invalid records, schema drift and idempotency as relevant.
3. Run real commands; capture exit codes and relevant output.
4. Report verified passes, failures, skipped checks and remaining risks; never claim unrun tests passed.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
