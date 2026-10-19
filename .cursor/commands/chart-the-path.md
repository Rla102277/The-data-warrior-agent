# /chart-the-path

---
name: chart-the-path
description: Plan an implementable engineering route.
---

# Chart The Path

**Disciplines:** Water, Fire

## Purpose
Plan an implementable engineering route. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Decompose objective into deliverables, dependencies, owners and testable milestones.
2. Identify risks, prerequisites, reversibility and rollout gates.
3. Define artifact-level acceptance tests and fallback paths.
4. Publish plan in PLAN.md and Battle Map; do not imply approval.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
