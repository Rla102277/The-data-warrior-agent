---
name: to-plan
description: Use when the ground gate is on the Scroll and the fight needs a rich campaign plan with phases, gates, flowchart, and mind map before a forge spec.
disable-model-invocation: true
---

# To Plan

Refuse to run if the Scroll is missing the ground gate from `/know-the-ground`. Call `the-scroll` to read it. Do not invent a decision, outcome, or single action.

This is the **campaign plan** for the fight — richer than `/to-spec`, earlier than build. Prefer Data Warrior words: **aim of this fight**, locked defaults, evidence on the terrain, phases, gates. **Never** use “north star,” “vision,” or similar slogan language.

## Where to write

Write `PLAN.md` at the project root (or under `forge-line/jobs/<job-id>/plan.md` if a job already exists). Link it from the Scroll and Battle Map. Do not start building.

## Required sections (in this order)

### 1. Title and aim of this fight
- Short title (project or fight name — not a slogan).
- **Aim of this fight** — one or two sentences from the Scroll decision + outcome (what choice improves, what “worth it” means).
- **Single action** — verbatim from the Scroll.
- Decision owner and when they decide.

### 2. Locked defaults
Bullet list of defaults already agreed (or recommended with tradeoffs labeled). Include only tools the ground named. No vendor assumed.

### 3. Non-goals
What this fight will **not** do in this wave. Keeps scope honest.

### 4. Architecture flowchart (Mermaid)
One `flowchart` (or `flowchart TB`) showing how the pieces named on the terrain connect for this action. Use simple node IDs (no spaces). Edge labels in quotes if they contain special characters. Do not invent systems not on the ground — mark unknowns as `Unknown_*` nodes.

### 5. Mind map (Mermaid)
One `mindmap` with the aim at the root and branches for phases, risks, owners, and proof. Again: no “north star” wording; root label can be the fight title or “Aim”.

### 6. Evidence on the terrain
A short table or list: path / source → what it teaches → observed vs assumed. Prefer real paths in the project. Do not invent evidence.

### 7. Phases
Numbered phases (0…N). Each phase has:
- Purpose (plain language)
- Deliverables
- **Pass gate** (how we know the phase is done)
- Explicit stop: what must not start until the gate passes

Phase 0 is usually “capture the decision on the Scroll” (may already be done — say so). Later phases stay unbuilt until earlier gates pass.

### 8. Suggested build order
Calendar-agnostic sequence of waves (docs → contracts → smallest slice → proof → expand). Not a Gantt chart.

### 9. First concrete execution after plan approval
The **first small commit wave** only — not the full stack. Name files to create and what not to Jobsite on day one.

### 10. Open assumptions and falsifiers
Pull falsifiers from the Scroll. List assumptions that still need owners.

## Style
- Plain language. Deshi: short teaching lines between sections if Role is Deshi; still deliver the full plan in one pass once ground is known.
- One plan artifact. Do not dump the same content into five files.
- After writing the plan, stop and ask for approval or edits. Next command when they are ready: `/to-spec` (then `/to-steps`, `/the-forge`). You do not call those commands yourself.

## Anti-patterns
- Building before the plan is accepted.
- Copying another product’s architecture that the ground did not name.
- Slogan words (“north star,” “transformational vision”).
- Phases without pass gates.
- Flowcharts that invent warehouses, vendors, or platforms.

Follow project instructions and THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
