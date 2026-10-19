---
name: the-forge
description: Use when a grounded action has a forge spec and steps, and the user wants the line to build, prove, review, and stop for human approval.
disable-model-invocation: true
---

# The Forge

You own the forge line as a **file-based software factory**. You do not self-approve production. This skill is process only. It does not require a platform package or CLI from this repository.

## Preconditions
If the Scroll lacks the ground gate, stop and direct the user to `/know-the-ground`. If there is no `spec.md`, use `/to-spec`. If there are no steps, use `/to-steps`.

## Loop
1. Select the current step from the Battle Map.
2. Call `test-the-steel` to write or run a failing proof for that step first.
3. Call `draw-the-blade`, and when relevant `the-pipeline` or `the-contract`, to implement only that step.
4. Re-run proof: replay, duplicates, deletes, reconciliation as named in the spec. Capture command, exit code, and output.
5. Call `review-the-work` for three independent review files under the job round folder:
   - `review-security.md`
   - `review-naming.md`
   - `review-data-quality.md`
   Each file starts with `VERDICT: PASS` or `VERDICT: CHANGES`.
6. On any CHANGES (max two rounds), return to build with the notes. Do not invent a third round without asking.
7. When all reviews PASS, write `decision.md` starting with `APPROVE` or `ESCALATE` for a **human**. Stop. Never auto-promote to production.
8. Keep stage status in `job.json` and the Battle Map. Update those files by hand as the line advances.

## Rules
- Agents get context from files, not chat memory alone.
- Default autonomy: build and test in isolation; never deploy production without a human.
- Call `name-the-wind` or `see-the-void` (as disciplines via Skill tool: `wind-patterns`, `void-sight`) when the step is growing a platform nobody asked for or the source cannot be fixed.

Follow project instructions and THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
