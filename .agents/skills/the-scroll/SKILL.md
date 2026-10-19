---
name: the-scroll
description: A living workshop that houses The Challenge and maintains evolving engineering knowledge.
---

# The Scroll

The Scroll is **the home of The Challenge**, not a document generator.
1. Read the existing Scroll if there is one; otherwise begin conversationally and create `SCROLL.md` when the first durable decision is made.
2. Run the interrogation method from `skills/the-interrogation/SKILL.md`: ask **one question at a time**, challenge answers, and recommend options.
3. After meaningful answers, update `SCROLL.md` with objective, verified facts, decisions and rationale, unresolved questions, glossary, contradictions, and acceptance criteria. Preserve previous reasoning; do not silently overwrite contradictions.
4. If the work becomes multi-stage or multi-session, offer `/the-battle-map`; keep its status in a short `BATTLE_MAP.md` adjacent to the Scroll.
5. Resume by reading the Scroll and asking the **next** important question, not restarting the interview.
6. When ready, the Scroll becomes the reference for architecture, implementation and tests. Documents support the conversation; they are not its purpose.
Only claim persistence after a successful file write.

Follow `THE_WAY.md`. Use the host's native model and tools; no custom server, mandatory CLI or separate model key. Respect real permissions and never fabricate evidence.
