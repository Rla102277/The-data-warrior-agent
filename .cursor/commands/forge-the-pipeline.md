# /forge-the-pipeline

---
name: forge-the-pipeline
description: Build robust batch or streaming data pipelines.
---

# Forge The Pipeline

**Disciplines:** Fire, Tools

## Purpose
Build robust batch or streaming data pipelines. Operate using the host agent's native model, repository context and available tools. No mandatory Python runtime, custom web UI or separate model key.

## Inputs
- Current user request, repository instructions and existing mission artifacts.
- Actual host tool capabilities and explicit mission authority.

## Procedure
1. Confirm source/sink contracts, keys, watermark semantics and replay requirements.
2. Design incremental, retry, deduplication, late-data and schema-evolution behavior.
3. Implement in the actual project stack, not an invented generic CSV platform.
4. Run representative integration tests and capture proof.

## Output contract
- State what was observed, changed, tested, blocked and left unresolved.
- Update applicable mission Markdown/JSON only through successful host tool operations.
- Provide concrete file paths and test evidence, not unsupported claims.

## Handoff and safety
- Check THE_WAY.md and the active mission's approved A/B/C authority before any modification or external action.
- Request authorization for actions outside the recorded scope. Never self-escalate or bypass host permission controls.
- Handoff requires named next skill, verified inputs, expected outputs, blocking risks and acceptance criteria.
- If a prerequisite is missing, stop and surface the missing evidence instead of fabricating it.
