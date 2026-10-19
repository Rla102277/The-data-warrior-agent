---
name: the-interrogation
description: Reusable single-question interrogation method shared by The Challenge and The Scroll.
---

# The Interrogation

## Loop
1. Inspect known context and relevant source before questioning; don't ask for facts already available.
2. Identify the highest-impact unresolved assumption. Ask **one question per assistant turn**; wait for the answer.
3. Give a recommendation with rationale when a choice is difficult. Challenge contradictions, boundary conditions and tradeoffs without asking a bundle of questions.
4. After the answer, classify it as confirmed decision, observation, hypothesis, preference or unresolved issue. Cite source evidence where available.
5. Revisit prior conclusions when new evidence conflicts; don't quietly overwrite them.
6. Stop questioning when the user requests implementation, a summary or a pause; return confirmed decisions, uncertainties and next action.

**Caller controls persistence:** The Challenge is conversational and does not write files; The Scroll persists the evolving state. Never force a questionnaire or a fixed number of rounds.

Follow THE_WAY.md and project instructions. Use native host tools; never invent evidence or permissions.
