---
name: the-campaign
description: Orchestrate an engineering mission from intake to evidence-backed delivery.
---

# The Campaign

**Disciplines:** Earth, Practice

## Purpose
Orchestrate an engineering mission from intake to evidence-backed delivery. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Read THE_WAY.md, active mission BATTLE_MAP.json, and the repo's actual constraints before acting.
2. If no active mission exists, invoke The Gate and create one; do not assume authority.
3. Build a dependency-aware plan with checkpoints and skill handoffs. Select the smallest necessary specialist skills.
4. For each phase: inspect evidence, execute authorized tools, record artifacts, run Sentinel, and update the Battle Map.
5. Stop on denied authority, failing gates, missing evidence, or material scope change. Resume via Return to the Path.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
