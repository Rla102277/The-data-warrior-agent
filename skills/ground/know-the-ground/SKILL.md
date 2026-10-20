---
name: know-the-ground
description: Use when a data engineer or analyst is starting a project or task and the real decision, grain, and single action are not yet written.
disable-model-invocation: true
---

# Know The Ground

This is the grill. Most data work fails here — not in execution, but in diagnosis. Call the Skill tool for `grounding` and `the-scroll`. Ask **exactly one consequential question per turn**. Speak in plain language. Prefer everyday words over engineering jargon unless the human uses jargon first.

Stated problem is not always the real problem. Your job is detective work before any forge build.

## Tools
Do not assume a platform, warehouse, lakehouse, or vendor. Record the tools already on the terrain. Bring a new tool only when the single action needs it, and only through tool choice. A favorite stack is not a diagnosis.

## Where the code lives
If the Scroll has no `repo_host` from `/setup-the-forge`, send them to `/setup-the-forge` (welcome + menus) before talking about pull requests, pipelines, or builds. Do not assume GitHub. If they insist on answering here, use the same numbered menu as setup Menu A.

## Ground gate (required before any forge spec)
Do not call `/to-spec` or `/the-forge` until the Scroll can answer these. Ask the human in plain words (adapt wording; keep the meaning):

1. **What decision must change?** Who decides, and when do they decide?  
   Example ask: “If this works, whose choice gets better — and when do they make that choice?”
2. **What outcome would justify the work?** Success as *they* define it — a real-world result, not a deliverable name.  
   Example ask: “What would have to be true afterward for you to say this was worth it?”
3. **What is the terrain?** What the answer is about (grain), where truth comes from, limits, incentives, and the **cost of being wrong**.  
   Example ask: “What is one row or answer about, where does the truth come from, and what goes wrong if we get it wrong?”
4. **What evidence would change our minds?**  
   Example ask: “What would we see that would make us change or stop this plan?”
5. **Who will own the result** after the build team moves on?  
   Example ask: “Who keeps this correct after we leave?”
6. **The single action in one sentence** — demand simplicity. If it cannot be stated, the analysis is not done.  
   Example ask: “In one sentence, what is the one thing we will do?”

Also surface stated-versus-real problem, delete or late-arrival needs, and whether resistance is political or valid. Prefer defaults with tradeoffs. When the gate is met, write the Scroll and hand off to `/to-spec` without starting a build.

If the terrain shows the work cannot succeed (void or wind), say so and stop rather than forging a polished failure.

Follow project instructions and THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
