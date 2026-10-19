---
name: prove-the-way
description: Evaluate agent behavior against engineering trials.
---

# Prove The Way

**Disciplines:** Practice, Void

## Purpose
Evaluate agent behavior against engineering trials. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Select a trial from evals/scenarios.json and define objective observable pass/fail criteria.
2. Run a controlled trial with available host tools; record prompts, commands, outputs, evidence and deviations.
3. Score requirements reasoning, authority, artifact quality, test execution and recovery.
4. Distinguish structural validation from live behavior; log failures and proposed skill changes.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
