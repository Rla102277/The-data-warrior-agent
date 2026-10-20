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

- **Deshi:** Use the full deeper template (why, checklist, ask, examples). After their answer, teach what you locked and what you still need if vague. Confirm consequential interpretations before the Scroll. Still one question per turn.
- **Rōnin:** Full template each turn; keep why tight but do not skip the checklist.
- **Kensei:** Same ask shape; name system risks when they appear; still complete all six.

## Ground gate (required before any forge spec)

Do not call `/to-spec` or `/the-forge` until all six are on the Scroll.

**How to ask each question (all levels):** Label `Ground question N of 6`. In the same turn give, in order:

1. **Why this matters** — use the deeper why below (2–4 short sentences). Help them understand the trap we are avoiding.
2. **What a strong answer includes** — the checklist for that step.
3. **Ask** — plain words; they may answer in a few short lines.
4. **Examples** — two full answers they can imitate.
5. **Not enough yet** — show the vague phrases we will push back on.

Do not use cryptic slogans. If their answer is vague, do **not** advance: reflect what you heard, explain what is missing using the checklist, give one tighter example, and ask the same numbered question again.

### Ground question 1 of 6 — Decision
**Field:** who will decide differently, and the moment they decide.  
**Why this matters:** Clever pipelines and pretty dashboards still fail when nobody’s *choice* changes. We are not looking for “stakeholders” or “users of the report.” We are looking for the person who will say yes/no, buy/don’t buy, hire/cut, order more/less — and the recurring moment when they make that call. If we cannot name that person and that moment, we do not have a fight yet; we have a wish. Everything else we build should serve that decision occasion.  
**What a strong answer includes:**  
- A person or job title you could email (not a department blob).  
- The decision they make (approve spend, place an order, close the books, green-light a project).  
- When that usually happens (day, meeting, deadline, ritual).  
**Ask:** “If this work succeeds, who will decide something differently — and when do they usually make that decision? Name the person or role, the decision, and the moment.”  
**Examples:**  
- “Sam, store manager — she decides how much to reorder each SKU every Monday morning before the supplier cutoff.”  
- “Priya, CFO — she approves or cuts discretionary spend in the monthly board pack the first Thursday of the month.”  
**Not enough yet:** “leadership,” “the business,” “users,” “anyone who opens the dashboard,” “whenever we need it.”

### Ground question 2 of 6 — Outcome
**Field:** success as a real-world result, not a deliverable name.  
**Why this matters:** Shipping a report is not the same as winning. We need the consequence you would bet your reputation on — something you could observe in the world after the decision-maker acts. That outcome is how we know whether the Forge work was worth the cost. If success is only “we have visibility,” we will never know when to stop building.  
**What a strong answer includes:**  
- A change you could notice without looking at our code (behavior, money, time, risk, trust).  
- Roughly when you would expect to see it.  
- Optionally how you would know (a number, a deadline met, a fight that stops happening).  
**Ask:** “Imagine we are looking back in a few months. What would have to be true in the real world for you to say this was worth it — not that a report exists, but that something out there got better?”  
**Examples:**  
- “Stockouts on our top 50 SKUs drop by about half within one quarter, and Sam stops emergency mid-week orders.”  
- “Accounting closes the books on day 3 without a weekend spreadsheet scramble, three closes in a row.”  
**Not enough yet:** “we have a report,” “visibility,” “better analytics,” “one source of truth,” “stakeholders are happy.”

### Ground question 3 of 6 — Terrain
**Field:** grain, source of truth, limits, incentives, cost of being wrong.  
**Why this matters:** Wrong grain (what one row means) or the wrong system of record produces *confident* wrong answers — the most expensive kind. Before we build, we need the shape of the truth: what one answer is about, which system wins when systems disagree, and what it costs the decision-maker if we are wrong. Also notice incentives: if someone is rewarded for a flattering number, that is part of the terrain.  
**What a strong answer includes:**  
- **Grain:** what one row or one answer means (one store-SKU-day, one invoice, one employee-month).  
- **Source of truth:** which system we trust when two systems disagree.  
- **Cost of being wrong:** what the decision-maker suffers if our number lies (lost sales, bad spend, compliance, trust).  
- Optional: known limits (late feeds, missing stores, manual overrides) or incentive pressure.  
**Ask:** “Help me see the ground: (1) What is one answer or one row about? (2) When two systems disagree, which one do we trust? (3) If we get it wrong, what bad thing happens to the person who decides?”  
**Examples:**  
- “One row = one store–SKU–day. Trust the POS export over the Excel forecast. Wrong → Sam under-orders and we lose sales; over-order and we tie up cash.”  
- “One answer = cash by cost center for the last closed month. Trust the GL, not the project tracker. Wrong → Priya green-lights spend we do not have.”  
**Files:** If samples are still missing, add: “If you have a spreadsheet, schema, or screenshot that shows the real shape, attach it with this answer — it beats describing from memory.”  
**Not enough yet:** “all the data,” “the warehouse,” “it depends,” “we’ll clean it later,” listing tools with no grain.

### Ground question 4 of 6 — Falsifiers
**Field:** what would make us change or stop.  
**Why this matters:** Without a kill signal we polish a bad plan. A falsifier is not “if it doesn’t work” — it is a specific observation that would force us to rewrite the approach or stop the fight. Naming it keeps us honest when ego and sunk cost want to keep building.  
**What a strong answer includes:**  
- Something you could actually observe (a feed late N times, a person who refuses to use the number, a definition fight that won’t die).  
- What we would do if we saw it (pause, fix the feed first, get sign-off, walk away).  
**Ask:** “What would we see — a concrete signal — that would make us change this plan or stop? And what would we do if we saw it?”  
**Examples:**  
- “If Monday’s POS feed is late more than two weeks in a row, we stop feature work and fix the feed first.”  
- “If Priya will not use the number unless Finance signs the definition, we pause the build until that sign-off exists.”  
**Not enough yet:** “if it doesn’t work,” “bad data,” “nothing,” “we’ll adapt,” “low adoption” with no threshold.

### Ground question 5 of 6 — Owner
**Field:** who keeps it correct after the build team leaves.  
**Why this matters:** Definitions drift, feeds break, and mappings rot. Unowned work dies slowly while still looking “done.” The owner is not “whoever built it” and not a whole department — it is the person who will notice when the number is wrong and has the authority (or duty) to fix the meaning. If nobody owns it, say so; that may be a reason to refuse or shrink the fight.  
**What a strong answer includes:**  
- A named person or a specific on-call role.  
- What they own (definition, feed check, mapping, weekly reconciliation).  
- Roughly how often they touch it.  
**Ask:** “After we leave, who is responsible for keeping this correct — the meaning of the numbers and the feeds behind them? Name a person or role, and what they own.”  
**Examples:**  
- “Jordan in Finance Ops owns the close definition and runs a weekly reconciliation check every Tuesday.”  
- “The store-ops analyst on-call owns SKU mapping when items change; they update the mapping table the same day.”  
**Not enough yet:** “IT,” “the data team,” “the team,” “shared ownership,” “we’ll figure it out later.”

### Ground question 6 of 6 — Single action
**Field:** one action in one sentence.  
**Why this matters:** If we cannot say the *one* thing we will do, we are still collecting wishes. The single action is the bridge from diagnosis to the Forge: one verb, one object, aimed at the decision-maker and the moment from question 1. Feature lists and “and also…” mean we have not chosen yet. Choosing one action is how we protect focus and know when V1 is done.  
**What a strong answer includes:**  
- One sentence.  
- One clear verb (put, give, show, stop, wire…).  
- Who it is for and, if possible, when they use it — tying back to question 1.  
**Ask:** “In one sentence only: what is the single thing we will do so that person can decide better at that moment? If you need ‘and,’ we probably still have two fights.”  
**Examples:**  
- “Put last week’s stockout risk by store–SKU on Sam’s Monday ordering screen before the supplier cutoff.”  
- “Give Accounting one trusted cash-by-cost-center number on day 2 of close, sourced from the GL.”  
**Not enough yet:** a paragraph, a roadmap, a feature list, “improve the pipeline and also rebuild the model…”

Also surface stated-versus-real problem, delete or late-arrival needs, and whether resistance is political or valid when they come up — without skipping the numbered sequence.

When the gate is met, write the Scroll and hand off to `/to-spec` without starting a build. If the terrain shows the work cannot succeed (void or wind), say so and stop rather than forging a polished failure.

Follow project instructions and THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
