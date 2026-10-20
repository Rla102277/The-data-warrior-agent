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

- **Deshi:** Teach between questions using the why + examples for that step. Confirm consequential interpretations before locking them on the Scroll. Still one question per turn — teaching does not replace the next ask.
- **Rōnin:** Short acknowledge, then why + ask + examples for the next question.
- **Kensei:** Same ask shape; name system risks when they appear; still complete all six.

## Ground gate (required before any forge spec)

Do not call `/to-spec` or `/the-forge` until all six are on the Scroll.

**How to ask each question (all levels):** Label `Ground question N of 6`. In the same turn give (1) one short **why**, (2) the **ask** in plain words, (3) **two example answers** they can imitate. Do not use cryptic slogans (“who chooses first”). Reject vague answers and ask once more with a tighter example.

### Ground question 1 of 6 — Decision
**Field:** who will decide differently, and the moment they decide.  
**Why:** Most data work fails by building something that never changes a real choice. If we cannot name the person and the occasion, we do not have a fight yet.  
**Ask:** “Who will make a real decision differently if this works? Name a person or job title, and when they usually make that decision.”  
**Examples:**  
- “Sam (store manager) — every Monday morning before she places the stock order.”  
- “The CFO — in the monthly board pack when they approve or cut spend.”  
**Not enough yet:** “leadership,” “the business,” “users,” “whenever we need it.”

### Ground question 2 of 6 — Outcome
**Field:** success as a real-world result, not a deliverable name.  
**Why:** “A dashboard exists” is not success. Success is what is different in the world after they decide.  
**Ask:** “What would have to be true afterward for you to say this was worth it?”  
**Examples:**  
- “Stockouts on top 50 SKUs drop by half within one quarter.”  
- “Accounting can close the books on day 3 without a spreadsheet scramble.”  
**Not enough yet:** “we have a report,” “visibility,” “better analytics.”

### Ground question 3 of 6 — Terrain
**Field:** grain, source of truth, limits, incentives, cost of being wrong.  
**Why:** Wrong grain or the wrong system of record produces confident wrong answers. We need the shape of the truth before we build.  
**Ask:** “What is one answer or one row about? Which system do we trust when systems disagree? What goes wrong if we get it wrong?”  
**Examples:**  
- “One row = one store-SKU-day. Trust the POS export over the spreadsheet. Wrong → we under-order and lose sales.”  
- “One answer = cash by cost center for last closed month. Trust the GL. Wrong → we green-light spend we do not have.”  
**Files:** If samples are still missing, add: “If you have a file that shows the real shape (spreadsheet, schema, screenshot), attach it with this answer.”  
**Not enough yet:** “all the data,” “the warehouse,” “it depends.”

### Ground question 4 of 6 — Falsifiers
**Field:** what would make us change or stop.  
**Why:** Without a kill signal we polish a bad plan. Name what would force a rewrite or a stop.  
**Ask:** “What would we see that would make us change or stop this plan?”  
**Examples:**  
- “If Monday’s POS feed is late more than two weeks in a row, we stop and fix the feed first.”  
- “If the CFO will not use the number unless Finance signs off, we pause build until that sign-off exists.”  
**Not enough yet:** “if it doesn’t work,” “bad data,” “nothing.”

### Ground question 5 of 6 — Owner
**Field:** who keeps it correct after the build team leaves.  
**Why:** Unowned work rots. Someone named must keep definitions and feeds honest.  
**Ask:** “Who keeps this correct after we leave? Prefer a named person or role, not ‘the team.’”  
**Examples:**  
- “Jordan in Finance Ops owns the close definition and the weekly check.”  
- “The store-ops analyst on-call owns the SKU mapping when items change.”  
**Not enough yet:** “IT,” “the team,” “we’ll figure it out later.”

### Ground question 6 of 6 — Single action
**Field:** one action in one sentence.  
**Why:** If we cannot say the one thing we will do, the analysis is not done — we are still collecting wishes.  
**Ask:** “In one sentence, what is the one thing we will do?”  
**Examples:**  
- “Put last week’s stockout risk by store-SKU on Sam’s Monday ordering screen.”  
- “Give Accounting a single trusted cash-by-cost-center number on day 2 of close.”  
**Not enough yet:** a paragraph, a feature list, “improve the pipeline and also…”

Also surface stated-versus-real problem, delete or late-arrival needs, and whether resistance is political or valid when they come up — without skipping the numbered sequence.

When the gate is met, write the Scroll and hand off to `/to-spec` without starting a build. If the terrain shows the work cannot succeed (void or wind), say so and stop rather than forging a polished failure.

Follow project instructions and THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
