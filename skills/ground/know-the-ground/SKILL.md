---
name: know-the-ground
description: Use when a data engineer or analyst is starting a project or task and the real decision, grain, and single action are not yet written.
disable-model-invocation: true
---

# Know The Ground

This is the grill. Most data work fails here — not in execution, but in diagnosis. Call the Skill tool for `grounding` and `the-scroll`. Speak in plain language. Prefer everyday words over engineering jargon unless the human uses jargon first.

Stated problem is not always the real problem. Your job is detective work before any forge build.

## Keep going — do not stop mid-gate

Work through **all six** ground-gate questions. **One question per turn.** After each answer:

1. Briefly acknowledge (one or two sentences).
2. At **Deshi**, also teach: why this question matters, a simple example, and a recommended default with its tradeoff if useful — then confirm you heard them.
3. Write or update the Scroll field for that step when the answer is clear.
4. **Immediately ask the next unanswered question** in the same reply. Label it `Ground question N of 6`.
5. Do **not** end the turn with only a status summary (“setup is done”, “project is empty”, “real work starts with the decision”) and then go silent. That feels like a stop. If the gate is incomplete, the next question must be present.
6. Only after question 6 is answered: write the full ground block on the Scroll, state the single action, and offer `/to-spec` (or stop if void/wind).

If they go off-topic, gently return to the current numbered question.

## Tools
Do not assume a platform, warehouse, lakehouse, or vendor. Record the tools already on the terrain. Bring a new tool only when the single action needs it, and only through tool choice. A favorite stack is not a diagnosis.

## Where the code lives
If the Scroll has no `repo_host` from `/setup-the-forge`, finish `/setup-the-forge` menus first (one menu per turn, including **Menu G — files to share**), then **without pausing** start Ground question 1 of 6. Do not assume GitHub.

## Files to upload
If the Scroll has no `files_to_upload` answer yet, ask **before** Ground question 1 (or right after setup if you are mid-flow):

```text
Do you have any files to upload or attach for this work?
Reply with a number:
1) Yes — I will attach them in this chat now
2) Yes — they are already in this project folder (tell me the path next)
3) Not now — I may share files later
4) No files — we will work from conversation only
```

Wait for attachments if they pick 1. Record `files_to_upload` on the Scroll. Then continue with Ground question 1 of 6 in the next turn (or same turn if they chose 3/4). During terrain (question 3), invite files again if something is still missing (“If you have a sample file or schema, you can attach it now”).

## Role style while grilling

- **Deshi:** Teach between questions. Shorter words. Offer examples and a recommended default. Confirm consequential interpretations before locking them on the Scroll. Still one question per turn — teaching does not replace the next ask.
- **Rōnin:** Crisp acknowledge + next question.
- **Kensei:** Crisp acknowledge; name system risks when they appear; still complete all six.

## Ground gate (required before any forge spec)

Do not call `/to-spec` or `/the-forge` until all six are on the Scroll.

### Ground question 1 of 6 — Decision
**Field:** whose choice improves, and when they choose.  
**Ask:** “If this works, whose choice gets better — and when do they make that choice?”  
**Deshi add-on:** “We start here so we do not build a dashboard nobody decides from. Name a person (or role) and a moment — for example, ‘the store manager every Monday morning.’”

### Ground question 2 of 6 — Outcome
**Field:** success as *they* define it — a real-world result, not a deliverable name.  
**Ask:** “What would have to be true afterward for you to say this was worth it?”  
**Deshi add-on:** “Worth it means a consequence in the world (fewer stockouts, a yes/no call), not ‘a report exists.’”

### Ground question 3 of 6 — Terrain
**Field:** grain, source of truth, limits, incentives, cost of being wrong.  
**Ask:** “What is one row or answer about, where does the truth come from, and what goes wrong if we get it wrong?”  
**Deshi add-on:** “Grain = what one line means. Source of truth = which system we trust when systems disagree.”  
**Files:** If they still have no samples, add: “If you have a file that shows the real shape (spreadsheet, schema, screenshot), you can upload or attach it with this answer.”

### Ground question 4 of 6 — Falsifiers
**Field:** what would make us change or stop.  
**Ask:** “What would we see that would make us change or stop this plan?”  
**Deshi add-on:** “This keeps us honest. Name one signal that would kill or rewrite the plan.”

### Ground question 5 of 6 — Owner
**Field:** who keeps it correct after the build team leaves.  
**Ask:** “Who keeps this correct after we leave?”  
**Deshi add-on:** “If nobody owns it, it will rot. Prefer a named role over ‘the team.’”

### Ground question 6 of 6 — Single action
**Field:** one action in one sentence.  
**Ask:** “In one sentence, what is the one thing we will do?”  
**Deshi add-on:** “If it takes a paragraph, we are not done. Push for one verb and one object.”

Also surface stated-versus-real problem, delete or late-arrival needs, and whether resistance is political or valid when they come up — without skipping the numbered sequence.

When the gate is met, write the Scroll and hand off to `/to-spec` without starting a build. If the terrain shows the work cannot succeed (void or wind), say so and stop rather than forging a polished failure.

Follow project instructions and THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
