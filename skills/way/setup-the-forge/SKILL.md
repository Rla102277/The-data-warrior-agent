---
name: setup-the-forge
description: Use when starting a project or setting up once — welcome, guiding principles, then menu-driven setup for where code lives and job paths.
disable-model-invocation: true
---

# Setup The Forge

This is the start of a project. Speak in plain language. **One menu per turn.** Wait for a number (or a clear pick) before the next menu. Do not assume GitHub or any vendor.

## Turn 0 — Welcome (always first)

Before any setup menu, show this welcome (adapt lightly; keep the meaning). If `WELCOME.md` exists in the project, you may open with its contents instead.

```text
Welcome — The Data Warrior

You are the Data Warrior. We are here to change a decision — not to ship busywork.
Technical completion is not strategic success.

Guiding principles
1. Know the decision before the build.
2. Demand simplicity — one action in one sentence.
3. Embrace discipline — real tests; a person approves anything that goes live.
4. Measure clearer decisions and waste avoided — not dashboards or lines of code.
5. Tools are instruments — no platform assumed; bring tools only when the work needs them.
6. One clear question (or menu) at a time while we ground the work.
7. The sword is not the warrior — you stay in charge.

Reply with 1 to continue to setup.
```

Wait for them to continue. Then run the menus below, **one per turn**.

## Menus (one per turn)

Present each as a numbered list. Accept the number or the matching label. If they say “whatever you recommend,” pick the starred default and say which number you chose. After each answer, record the Scroll field.

### Menu A — Where the code lives
Scroll field: `repo_host`

```text
Where does this project’s code live for the team?
Reply with a number:
1) GitHub
2) Azure DevOps (Microsoft’s project site — boards, repos, pipelines)
3) GitLab
4) Bitbucket
5) Somewhere else (you will name it next)
6) Only on this computer for now — nothing shared yet
```

If they pick 5, next turn ask only for the name, then set `repo_host: other:<name>`. Map: 1→`github`, 2→`azure_devops`, 3→`gitlab`, 4→`bitbucket`, 6→`local_only`. You may check `git remote -v` only to confirm after they answer — never as a silent default.

### Menu B — Living notes (Scroll)
Scroll field: scroll path. Default ★ = `SCROLL.md` at project root.

```text
Where should we keep the living notes for this work?
(A simple file that remembers decisions so the next session does not start from zero.)
Reply with a number:
1) ★ Recommended — SCROLL.md at the top of the project
2) I will name a different file or folder
```

If 2, next turn ask for the path only.

### Menu C — Job folders
Scroll field: jobs path. Default ★ = `forge-line/jobs/`.

```text
Where should we keep the work tickets the Forge creates?
Reply with a number:
1) ★ Recommended — forge-line/jobs/
2) I will name a different folder
```

### Menu D — Proof and reviews
Scroll field: proof location. Default ★ = inside each job folder.

```text
Where should proof and review notes live?
(The evidence that a step actually worked.)
Reply with a number:
1) ★ Recommended — inside each job’s folder
2) I will name a different place
```

### Menu E — How much the assistant may do alone
Scroll field: autonomy (default ★ = Level 2). Never auto-approve production.

```text
How much should the assistant do on its own?
Reply with a number:
1) ★ Recommended — build and test in a safe place; a person always approves anything that goes live (Level 2)
2) Suggest only — show plans; wait for me before building (Level 1)
3) I need a different arrangement (say what you need)
```

### Menu F — Forge command-line tool
Scroll field: `forge_cli` yes/no. Prefer checking whether `forge` runs; still confirm with the menu if unclear.

```text
Is the Forge command-line tool available in this project?
(It records jobs and proof. Optional if you are not using jobs yet.)
Reply with a number:
1) Yes — forge is installed / available
2) No — not installed here
3) I am not sure — check for me and tell me what you found
```

## After the menus

Write a short setup block into `SCROLL.md` (or the chosen scroll path) under a decision id, including `repo_host`. Create missing empty directories only. Summarize the choices in plain language. Do not start a job. Do not set up GitHub Actions, Azure Pipelines, or any host tooling until the ground says that is needed.

Tell them the next command is **`/know-the-ground`** when they are ready to name the real decision.

Follow project instructions and THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
