---
name: the-scroll
description: Socratic specification interview with living Markdown artifacts.
---

# The Scroll

**Disciplines:** Earth, People

## Purpose
Socratic specification interview with living Markdown artifacts. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Read or create mission SPEC.md, GLOSSARY.md, DECISIONS.md, QUESTIONS.md and EVIDENCE.md.
2. Ask one high-value question per turn; update durable Markdown after each answer using actual workspace tools.
3. Separate facts, hypotheses, decisions, contradictions, and acceptance tests with sources.
4. Surface conflicting answers rather than silently overwriting them.
5. Never claim to have persisted anything unless a write tool succeeded.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
