---
name: setup-the-forge
description: Use when starting a project or setting up once — welcome, level menu, guiding principles, then menu-driven paths for code host and jobs.
disable-model-invocation: true
---

# Setup The Forge

This is the start of a project. Speak in plain language. **One menu per turn.** Wait for a number before the next menu. Do not assume GitHub or any vendor.

On folder open / new chat, Cursor hooks and `AGENTS.md` already require welcome + **level**. If the human has not picked a level yet, do Turn 0 and Menu Level first.

## Turn 0 — Welcome (always first if not already shown)

Show this welcome (or `WELCOME.md` if present). Then wait for continue.

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

Reply with 1 to continue.
```

## Menu Level — How we work together (required early)

Scroll / AGENTS field: `Role:` (Deshi | Rōnin | Kensei). Styles only — never grant permissions.

```text
How should we work together on this project?
Reply with a number:
1) Deshi — Apprentice: teach me, explain tradeoffs, confirm before big edits
2) ★ Rōnin — Practitioner: act within the agreed scope and report outcomes
3) Kensei — Master: anticipate system-wide risk; still no extra permissions
```

Update `AGENTS.md` Role line after they pick. Default ★ if they say “whatever you recommend” → 2.

## Menus A–F (one per turn)

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

If 5, next turn ask only for the name → `repo_host: other:<name>`. Map: 1→`github`, 2→`azure_devops`, 3→`gitlab`, 4→`bitbucket`, 6→`local_only`. Confirm remotes only after they answer.

### Menu B — Living notes (Scroll)
Default ★ = `SCROLL.md` at project root.

```text
Where should we keep the living notes for this work?
Reply with a number:
1) ★ Recommended — SCROLL.md at the top of the project
2) I will name a different file or folder
```

### Menu C — Job folders
Default ★ = `forge-line/jobs/`.

```text
Where should we keep the work tickets the Forge creates?
Reply with a number:
1) ★ Recommended — forge-line/jobs/
2) I will name a different folder
```

### Menu D — Proof and reviews
Default ★ = inside each job folder.

```text
Where should proof and review notes live?
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
Scroll field: `forge_cli` yes/no.

```text
Is the Forge command-line tool available in this project?
Reply with a number:
1) Yes — forge is installed / available
2) No — not installed here
3) I am not sure — check for me and tell me what you found
```

### Menu G — Files to share
Scroll field: `files_to_upload:` `none` | `pending` | `received` (list names when received).

Ask in plain language. Examples of useful files: sample spreadsheets, schema exports, screenshots, requirement docs, pipeline JSON, data dictionaries — whatever helps us see the truth.

```text
Do you have any files to upload or attach for this work?
(Spreadsheets, schemas, screenshots, requirement docs, sample data, etc.)
Reply with a number:
1) Yes — I will attach them in this chat now (use the paperclip / attach control)
2) Yes — they are already in this project folder (tell me the path next)
3) Not now — I may share files later
4) No files — we will work from conversation only
```

If they pick 1: wait for the attachment(s) before the next menu or ground question; acknowledge each file by name; set `files_to_upload: received` with names.  
If they pick 2: next turn ask only for the path(s), then confirm what you can open.  
If 3 or 4: set `none` or `pending` and continue.  
At **Deshi**, explain that files reduce guessing — then still continue.

## Keep going — finish every menu

After each menu answer: acknowledge briefly, record the field, **immediately show the next menu** in the same reply. Label progress (`Setup menu C of G`, etc.). Do not stop after Menu A because `repo_host` is set. Complete Level (if needed) and **A–G** unless they explicitly pause.

## After the last setup menu

Write a short setup block into the Scroll under a decision id, including `repo_host`, Role, and `files_to_upload`. Create missing empty directories only.

Then **do not stop**. In the **same reply**, start `/know-the-ground` with **Ground question 1 of 6** (decision). One short “setup saved” line is enough — never a long “project is empty / real work starts later” closing that leaves them without the next question.

At **Deshi**, add one teaching sentence about why we grill the decision next, then ask question 1.

Do not start a Forge job. Do not wire CI until the ground says so.

Follow project instructions and THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
