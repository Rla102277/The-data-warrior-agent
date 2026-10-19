# THE DATA WARRIOR

**Native engineering skills for Cursor, Codex and Claude Code.** One product identity, no product version names.

## Start here
Open this repository in Cursor Agent. Invoke `/the-campaign` for end-to-end work, `/the-challenge` for one-question-at-a-time interrogation, or `/the-scroll` for a living specification. The host model and its native tools perform all work; no server, Python runtime, or separate LLM credentials are needed to use skills.

## Architecture
**The Way** constitution · **The Dojo** composable skills · **The Council** expert review · **The Forge** host-native tool execution · **The Chronicle** durable project knowledge · **The Trials** scenario-based evaluation.

The Campaign coordinates skill handoffs and quality gates, but it is not an independently running scheduler. A/B/C autonomy is an instruction-level operating agreement; enforce real permissions with host approvals, GitHub branch rules, Azure RBAC and CI.

## Layout
- `.agents/skills/<name>/SKILL.md` canonical agent skill definitions.
- `.cursor/commands/<name>.md` native Cursor commands.
- `.claude/skills/<name>/SKILL.md` Claude-compatible definitions.
- `.cursor/rules/the-way.mdc` persistent Cursor rule.
- `.warrior/missions/` durable mission state, created during work.
- `templates/` starter artifacts.
- `evals/` behavioral trial scenarios.
- `scripts/` optional standard-library checks and installation.

## A first real mission
```
/the-campaign
Build an incremental ingestion pipeline with duplicate handling,
late-arriving records, replay safety, schema evolution and runnable tests.
Begin in Deshi mode. Inspect the repository first, record a Battle Map,
ask for authorization before modifying files, and show actual test results.
```

## Install into another project
Copy `.agents/skills`, `.cursor/commands`, `.cursor/rules/the-way.mdc`, and optionally `.claude/skills` into the target repository. Merge rather than overwrite its existing `AGENTS.md` and project instructions. Or run `python3 scripts/install.py /path/to/project` if Python is available; it is an optional installer, not the skills runtime.

## Verify
```bash
python3 scripts/verify.py
python3 -m unittest discover -s tests -v
```
These validate file structure and contract expectations, **not** live model behavior. Follow `docs/LIVE-TESTING.md` to test in Cursor.

## GitHub
This public repository is the canonical source for The Data Warrior. The old separate repository is not used. Use feature branches and pull requests; never store credentials, mission secrets or customer data in the public repository.
