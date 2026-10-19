# THE DATA WARRIOR

**Small skills. Deep engineering judgment. No ceremony.**

Fourteen focused native agent skills for Cursor, Claude Code and Codex, grounded in evidence and Musashi-inspired practice. No custom model gateway or mandatory runtime.

## Install
```bash
python3 scripts/install.py /path/to/project the-scroll forge-the-pipeline --host cursor
# alternatives: --host claude, --host codex, --host all
```
The installer includes `THE_WAY.md` and initializes `Role: Rōnin` in a missing project `AGENTS.md` without overwriting existing instructions. Switch role by setting `Role: Deshi`, `Role: Rōnin` or `Role: Kensei`. These roles affect collaboration, **not permissions**.

## Choose a skill
- `/the-challenge`: interrogate assumptions, one question at a time, no files.
- `/the-scroll`: **The Challenge with memory**, evolving `SCROLL.md` and preserved decision history.
- `/the-battle-map`: optional `BATTLE_MAP.md` for evidence-backed progress and resumption.
- `/survey-the-ground`: inspect actual systems.
- `/study-the-wind`: compare approaches.
- `/council-of-masters`: specialist design review.
- `/chart-the-path`: implementation plan.
- `/draw-the-blade`: implement and verify.
- `/forge-the-pipeline`: CDC, watermarks, replay, MERGE, SCD2, deletes, Data Vault.
- `/forge-a-contract`: schema and producer-consumer guarantees.
- `/test-the-steel`: test correctness.
- `/sharpen-the-blade`: measured optimization.
- `/lessons-of-battle`: learn from evidence.
- `/the-campaign`: optional multi-stage coordination.

## Maintain and test
```bash
python3 scripts/sync.py
python3 scripts/verify.py
python3 -m unittest discover -s tests -v
python3 scripts/eval.py # shows NOT_RUN by default
python3 scripts/eval.py --execute --scenario challenge-one-question
```
The optional behavioral harness requires a locally installed, authenticated Claude CLI. It captures a transcript and grades a conservative one-question heuristic; **manual review is required**. It does not run automatically in CI or bypass tool permissions. See `docs/LIVE-TESTING.md`.

Canonical skills live in `skills/`; host adapters are generated. Fabric is an optional target; this project is independent of Foundation.
