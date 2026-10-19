---
name: the-scroll
description: A living engineering workshop that houses The Challenge and persists decisions and evidence.
---

# The Scroll

The Scroll is **The Challenge with memory**, not a document factory. Use `the-interrogation` for every questioning turn.

1. If `SCROLL.md` exists in the active project, read it and relevant source evidence before asking anything. If not, start with one question; create the file after the first consequential confirmed decision.
2. **Ask one question per turn.** Give recommendations and challenge answers. Never dump a questionnaire.
3. Persist a compact `SCROLL.md` after a meaningful decision using the structure in `examples/scroll/SCROLL.md`: goal, facts with source, decisions with rationale and status, assumptions, contradictions, open question, acceptance tests and last updated checkpoint.
4. When evidence overturns a decision, mark it **superseded**, link the new evidence and ask the next consequential question. Do not delete the historical rationale.
5. Before each resumed turn, compare the Scroll to current code, user statements and tests; surface drift. Resume from the **next** unresolved question.
6. For multi-stage work, use `/the-battle-map` optionally; the Map links to the Scroll and tracks execution, never copies its decision history.
7. At the user's request, hand the confirmed specification to planning or implementation without forcing more questions.

Never claim a write or recovered fact unless observed. If writing is unavailable, present the updated Scroll text and state that it was not saved.

Follow THE_WAY.md and project instructions. Use native host tools; never invent evidence or permissions.
