---
name: the-interrogation
description: Shared one-question-at-a-time challenge method; internal reusable skill.
---

# The Interrogation

## Method
1. Inspect supplied context and relevant repository facts before asking questions that the code already answers.
2. Find the most consequential uncertainty. Ask **exactly one question**. Wait for the answer.
3. Give a reasoned recommendation when useful, then challenge the answer with counterexamples, tradeoffs and failure modes.
4. On each response, update the working understanding; distinguish fact, decision and assumption.
5. Continue until the user says stop or the important uncertainty is resolved. Summarize confirmed decisions and remaining unknowns.
Do not create files unless the invoking skill explicitly requests persistence.

Follow `THE_WAY.md`. Use the host's native model and tools; no custom server, mandatory CLI or separate model key. Respect real permissions and never fabricate evidence.
