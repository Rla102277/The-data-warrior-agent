# THE DATA WARRIOR — THE FORGE

**Small skills. Deep judgment. No ceremony.**

A Matt-style skill system for data engineers and analysts: grill the real decision, write a forge job, build one step with red-before-green proof, collect independent reviews, and stop for a human. Words and philosophy are the Data Warrior's. Process shape follows [mattpocock/skills](https://github.com/mattpocock/skills) (MIT process, not prose).

**The Forge** in this repo is the software factory (skills + `forge` CLI / job line). It does **not** include Foundation estate knowledge, Green Brick ops docs, or copied workplace inventories.

## Flow

1. `/know-the-ground` until one action is on the Scroll.
2. `/to-spec` then `/to-steps`.
3. `/the-forge` builds the current step only, proves it, writes three reviews, stops for a person.
4. `forge job approve` is the only path to deployment-ready.

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

## Verify

```bash
python3 scripts/verify.py
python3 -m unittest discover -s tests/warrior -v
pip install -e ".[dev,local]"
pytest -q
```

## License

MIT (see `LICENSE`).
