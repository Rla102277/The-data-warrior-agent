---
name: the-forge
description: Use when a grounded action has a forge spec and steps, and the user wants the line to build, prove, review, and stop for human approval.
disable-model-invocation: true
---

# The Forge

The sword is not the warrior. You own the forge line as an instrument of the Way. You do not self-approve production. A green build that does not change the named decision is still a failure.

## Preconditions
If the Scroll lacks the ground gate from `/know-the-ground`, stop and direct the user there. If there is no `spec.md`, use `/to-spec`. If there are no steps, use `/to-steps`.

## Loop
1. Select the current step from the Battle Map.
2. Call `test-the-steel` to write or run a failing proof for that step first.
3. Call `draw-the-blade`, and when relevant `the-pipeline` or `the-contract`, to implement only that step.
4. Re-run proof with `forge job test --job-id <id> -- <command>`. The recorded exit code is the result. Do not infer success from prose. Replay, duplicates, deletes, and reconciliation stay as named in the spec.
5. Call `review-the-work`. Keep the three Markdown files and record structured reviews with `forge job review` bound to that test's build:
   - `review-security.md`
   - `review-naming.md`
   - `review-data-quality.md`
   Each file starts with `VERDICT: PASS` or `VERDICT: CHANGES`.
6. On any CHANGES (max two rounds), return to build with the notes. Do not invent a third round without asking.
7. When all reviews PASS, write `decision.md` starting with `APPROVE` or `ESCALATE` for a **human**. Stop. Never auto-promote to production.
8. If the `forge` CLI is present, advance stage via `forge job` commands. `forge job verify` must be clean before approval. You write artifact files; the CLI owns stage fields in `job.json`. `--authorized` attests the operator on this host. It is not cryptographic identity.

## Rules
- Agents get context from files, not chat memory alone.
- Default autonomy Level 2.
- Call `name-the-wind` or `see-the-void` (as disciplines via Skill tool: `wind-patterns`, `void-sight`) when the step is growing a platform nobody asked for or the source cannot be fixed.
- Prefer `forge policy` / `forge.policies.evaluate_action` before mutations when the platform is installed.

Follow project instructions and THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
