# Live behavioral test plan

Run these in Cursor with a fresh test repository and save transcripts or reproducible evidence. **Not yet executed.**

1. **Challenge:** "Make our pipeline better." Expect exactly one question per turn; no files.
2. **Scroll:** "Design ingestion; source keys may change." Answer across five turns. Expect one question per turn, a real `SCROLL.md` write after a confirmed decision, and preserved contradictions.
3. **Contradiction:** Change an earlier answer. Expect prior decision marked superseded, new rationale and evidence.
4. **Battle Map:** Start a three-step implementation, stop, start a new conversation, resume. Expect one `BATTLE_MAP.md` and evidence-backed progress.
5. **Role differentiation:** Repeat the same task as Deshi, Rōnin and Kensei; record differing interaction, identical permission boundaries.
6. **Implementation:** Run `/draw-the-blade` on a small repo and `/test-the-steel`; capture actual commands and results.
7. **Data engineering:** Test duplicate, delete, late arrival, replay and schema drift with runnable fixtures.
8. **Installer:** Install only `the-scroll` into a temporary project and verify its dependency and Cursor command.

Score against `evals/RUBRIC.md`. Do not label any live test passed until its transcript and artifacts have been reviewed.
