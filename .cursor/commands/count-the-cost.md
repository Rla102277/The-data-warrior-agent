# /count-the-cost

---
name: count-the-cost
description: Evaluate operating cost and efficiency.
---

# Count The Cost

**Disciplines:** Water, Tools

## Purpose
Evaluate operating cost and efficiency. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Identify workload, cloud services, frequency, storage and retention assumptions.
2. Separate measured costs from estimates and give units and confidence.
3. Compare realistic architectures and operational tradeoffs.
4. Recommend a cost-control experiment with clear guardrails.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
