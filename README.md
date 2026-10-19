# THE DATA WARRIOR

**Technical completion is not strategic success.**

A Matt-style skill system for data engineers, analysts, and neighboring roles who must change a decision — not ship another artifact. Words and philosophy follow [The Data Warrior's Manuscript](https://github.com/Rla102277/the-data-warriors-manuscript). Process shape follows [mattpocock/skills](https://github.com/mattpocock/skills) (MIT process, not prose).

The human is the Data Warrior. AI augments judgment. **The Forge** is the Tools companion in this repo: a ground-gated software factory (`forge` CLI / job line) that builds one proven step, collects independent reviews, and stops for a person. The sword is not the warrior. This repo does **not** include Foundation estate knowledge or workplace inventories. The book remains readable without this software.

## Mission

Close the strategic-discipline gap: demand one clear action, embrace boring execution, and measure success by decisions made clearer — not by models or pipelines delivered.

## Flow

1. `/know-the-ground` until the Scroll holds the Way's questions and one action in one sentence.
2. `/to-spec` then `/to-steps` — only after that gate.
3. `/the-forge` builds the current step only, proves it, writes three reviews, stops for a person.
4. `forge job test` records the real exit code. `forge job verify` must pass. `forge job approve --authorized` is the only path to deployment-ready, and that flag is an operator attestation, not cryptographic identity. Synthetic, stale, or tampered evidence is rejected.

## Installation

```bash
pip install -e ".[dev,local]"
./scripts/link-skills.sh
```

Or copy selected `skills/<bucket>/<name>/` folders into your agent skills directory. Run `/setup-the-forge` once per repo.

## Commands (user-invoked)

- **[win-the-room](./skills/fire/win-the-room/SKILL.md)**: Use when the deliverable is a recommendation that a decision-maker must accept, refuse, or defer.
- **[the-forge](./skills/forge/the-forge/SKILL.md)**: Use when a grounded action has a forge spec and steps, and the user wants the line to build, prove, review, and stop for human approval.
- **[to-spec](./skills/forge/to-spec/SKILL.md)**: Use when one agreed action exists on the Scroll and must become a forge job specification with proof criteria.
- **[to-steps](./skills/forge/to-steps/SKILL.md)**: Use when a forge spec exists and must be broken into ordered steps each small enough to build and fail a test.
- **[know-the-ground](./skills/ground/know-the-ground/SKILL.md)**: Use when a data engineer or analyst is starting a project or task and the real decision, grain, and single action are not yet written.
- **[see-the-void](./skills/void/see-the-void/SKILL.md)**: Use when incentives, power, culture, or a permanently broken source may decide whether the data work can succeed.
- **[adapt](./skills/water/adapt/SKILL.md)**: Use when requirements, terrain, or proof changed mid-task and remaining forge steps must be rewritten or the eighty-percent answer shipped.
- **[ask-the-warrior](./skills/way/ask-the-warrior/SKILL.md)**: Use when the user is unsure which Data Warrior command or forge stage fits the work in front of them.
- **[setup-the-forge](./skills/way/setup-the-forge/SKILL.md)**: Use when setting up a repository once to configure Scroll path, forge job folder, proof location, and autonomy defaults.
- **[name-the-wind](./skills/wind/name-the-wind/SKILL.md)**: Use when a data project is drifting into known failure patterns such as tool obsession, complexity as credibility, or the permanent draft.

## Disciplines (model-invoked)

- **[chart-the-path](./skills/forge/chart-the-path/SKILL.md)**: Use when converting a defined engineering objective into an implementation plan with dependencies, tests, rollback and milestones.
- **[draw-the-blade](./skills/forge/draw-the-blade/SKILL.md)**: Use when implementing a scoped code, SQL, notebook, infrastructure or pipeline change and verifying it.
- **[lessons-of-battle](./skills/forge/lessons-of-battle/SKILL.md)**: Use after a completed change, outage, incident or engineering experiment to capture reusable lessons and prevent recurrence.
- **[review-the-work](./skills/forge/review-the-work/SKILL.md)**: Use when a forge build needs independent security, naming, and data-quality review files before human approval.
- **[sharpen-the-blade](./skills/forge/sharpen-the-blade/SKILL.md)**: Use when refactoring or tuning a slow, expensive, fragile or hard-to-maintain data pipeline with measured before/after results.
- **[test-the-steel](./skills/forge/test-the-steel/SKILL.md)**: Use when validating a code or data pipeline change, investigating failed tests, or proving correctness under replay, deletes and schema drift.
- **[the-contract](./skills/forge/the-contract/SKILL.md)**: Use when defining or changing producer-consumer schemas, data quality guarantees, ownership, compatibility and data contract tests.
- **[the-pipeline](./skills/forge/the-pipeline/SKILL.md)**: Use when building or changing ingestion, batch/stream processing, CDC, incremental loads, Delta MERGE, SCD history or lakehouse pipelines.
- **[grounding](./skills/ground/grounding/SKILL.md)**: Use when interviewing for the real decision, stated-versus-real problem, grain, source of truth, and cost of being wrong before any build.
- **[simplicity](./skills/ground/simplicity/SKILL.md)**: Use when analysis or a pipeline design has grown past the single action the decision-maker can take right now.
- **[survey-the-ground](./skills/ground/survey-the-ground/SKILL.md)**: Use when entering an unfamiliar repository, diagnosing a data platform, or assessing schemas, pipelines and existing architecture before editing.
- **[tool-choice](./skills/ground/tool-choice/SKILL.md)**: Use when choosing between tools, platforms, or ingestion approaches for a data task and ego or resume pressure may dominate fitness.
- **[the-battle-map](./skills/practice/the-battle-map/SKILL.md)**: Use when work spans multiple stages, contributors or sessions and needs an evidence-backed progress map and restart point.
- **[the-challenge](./skills/practice/the-challenge/SKILL.md)**: Use when a user asks to pressure-test an idea, challenge assumptions, debate a design, or uncover hidden risks before implementation.
- **[the-scroll](./skills/practice/the-scroll/SKILL.md)**: Use when shaping an evolving engineering specification through challenging questions while preserving decisions, assumptions and contradictions across sessions.
- **[void-sight](./skills/void/void-sight/SKILL.md)**: Use when reading incentives, power, and culture that decide whether a data answer can be acted on.
- **[ship-the-eighty](./skills/water/ship-the-eighty/SKILL.md)**: Use when further analysis or pipeline polish will not change the recommendation and the reversible action is clear enough to ship.
- **[the-pivot](./skills/water/the-pivot/SKILL.md)**: Use when mid-task evidence shows the current approach cannot answer the decision and a controlled change of method is required.
- **[study-the-wind](./skills/wind/study-the-wind/SKILL.md)**: Use when choosing between engineering architectures, ingestion strategies, storage formats, orchestration approaches or tradeoffs.
- **[wind-patterns](./skills/wind/wind-patterns/SKILL.md)**: Use when diagnosing which failure pattern is active in a data initiative so the forge line can stop or redirect.


## What The Data Warrior Does

The human is the Data Warrior; the AI host supplies execution assistance. The Way provides decision discipline, while The Forge is an optional software-factory companion. This is not a standalone model gateway or a replacement for Cursor, Claude Code, or Codex.

| Capability | Purpose |
| --- | --- |
| Grounding | Identify the real decision, grain, source of truth, assumptions, consequences, and one concrete action. |
| Scroll and Battle Map | Preserve decisions, contradictions, verified progress, blockers, and the next action across sessions. |
| Architecture and planning | Compare data-engineering approaches, surface tradeoffs, and convert a grounded action into a spec and small testable steps. |
| Engineering | Guide implementation of SQL, Python, ingestion, CDC, incremental loads, contracts, and related changes. |
| Validation | Exercise correctness, replay, duplicates, deletes, schema drift, and other failure modes. |
| Reviews | Collect security, naming, and data-quality review perspectives before approval. |
| Governance | Track autonomy levels, evaluate policy constraints, and require explicit human approval. |
| Persistent jobs | Record stages, artifacts, messages, retries, rework, cancellations, and resume points on disk. |
| CLI and discovery | Offer job operations, policy evaluation, ADF/dbt discovery, lineage, and local demos. |
| Host portability | Install native skills and instructions for Cursor, Claude Code, and Codex. |

**Boundaries:** The Forge is not proof of production readiness merely because its CI passes. The current evidence gate checks for proof artifacts and three PASS review files, but some textual test claims and synthetic demo evidence are still accepted in demo paths. Independent agent behavior across hosts and real deployment authorization require separate validation. Fabric is an optional integration; Foundation estate knowledge is not part of this distribution.

## How to Use It

### 1. Clone and install

Requires Python 3.11+ and Git. In a terminal:

```bash
git clone https://github.com/Rla102277/The-data-warrior-agent.git
cd The-data-warrior-agent
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -e '.[dev,local]'
python scripts/verify.py
pytest -q
```

### 2. Add the skills to an existing project

Create the destination first. This copies skill files and creates host-specific instructions; it does not install a running background agent.

```bash
mkdir -p ~/data-warrior-sandbox
python scripts/install.py ~/data-warrior-sandbox --host cursor
# Or use --host claude, --host codex, or --host all
```

Open the destination project in your chosen host. Read `THE_WAY.md` and `AGENTS.md`. In Cursor, commands are available under `.cursor/commands`. You can instead copy only selected skills by passing their names after the destination.

### 3. Ground an engineering task

Start with `/know-the-ground` (or ask the agent to follow that skill). Answer one substantive question at a time until the Scroll states the decision, grain, source of truth, risks, and one actionable outcome. Use the Battle Map to retain verified progress and blockers across sessions.

### 4. Plan and implement

Use `/to-spec` to define acceptance criteria and `/to-steps` to create small, testable implementation steps. Invoke `/the-forge` to work through the current step, write tests, implement, validate, and prepare security/naming/data-quality reviews. Do not mistake a generated review for an independently executed review.

### 5. Inspect the Forge runtime

From the repository root, with the virtual environment active:

```bash
forge doctor
forge job create --title 'Local orders ingestion'
forge job list
forge job demo
```

The create command returns a job ID. Use it to inspect persisted state:

```bash
forge job inspect --job-id YOUR_JOB_ID
forge job resume --job-id YOUR_JOB_ID
```

`forge job demo` is a local demonstration, not a production approval. To approve an eligible job, the current CLI accepts `forge job approve --job-id YOUR_JOB_ID --actor human --authorized`; approval is gated on workflow stage and evidence. The flag expresses authorization to the CLI but does not independently authenticate the actor. Never use the demo's synthetic PASS artifacts as production proof.

### 6. Test before relying on it

```bash
python scripts/verify.py
python -m unittest discover -s tests/warrior -v
pytest -q
```

For a meaningful acceptance test, use a fresh project and require the agent to build an incremental orders pipeline, then challenge it with replay, duplicates, out-of-order versions, tombstones, checkpoint rollback, and invalid rows. Reopen the project in a new agent chat and check whether the Scroll and Battle Map accurately reconstruct decisions and outstanding risks. Record actual commands, exit codes, and artifact paths. A passing test suite validates the checked code paths; it does not establish that every host or production integration has been tested.

## Verify

```bash
python3 scripts/verify.py
python3 -m unittest discover -s tests/warrior -v
pip install -e ".[dev,local]"
pytest -q
```

## License

MIT (see `LICENSE`).
