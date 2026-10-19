---
name: ask-the-warrior
description: Use when the user is unsure which Data Warrior command or forge stage fits the work in front of them.
disable-model-invocation: true
---

# Ask The Warrior

You are the router over the **user-invoked** commands in this repo. Prefer the Way over the tool: if the decision is unclear, do not route to the Forge. Map the situation to one command. Do not invent a second command chain in the same turn.

## Route
1. New project or task with no clear decision, outcome, or single action yet → `/know-the-ground`.
2. One action is already on the Scroll, and they need a job file → `/to-spec`.
3. Spec exists, and they need ordered steps → `/to-steps`.
4. Spec and steps exist, ground gate is met, and they want to build → `/the-forge`.
5. Requirements or terrain changed mid-build → `/adapt`.
6. The deliverable is a recommendation people must accept → `/win-the-room`.
7. The work smells like a known failure pattern (tool obsession, complexity as credibility) → `/name-the-wind`.
8. Politics, incentives, or a broken org may kill the work → `/see-the-void`.
9. First time in this repo with these skills → `/setup-the-forge`.

State the chosen command, why it fits, and what evidence is still missing. Then stop so the user can invoke it.

Follow project instructions and THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
