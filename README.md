# THE DATA WARRIOR

**Small skills. Deep engineering judgment. No ceremony.**

Fourteen native-first agent skills for Cursor, Claude Code and Codex. The Scroll contains the Challenge's one-question-at-a-time interrogation and preserves decisions. The Battle Map tracks optional evidence-backed progress. Deshi, Rōnin and Kensei are selectable collaboration roles, never permission levels.

## Quick start
Clone this repository, then from its root:

```bash
python3 scripts/install.py /path/to/your/project the-scroll forge-the-pipeline --host cursor
```

For Claude Code use `--host claude`; for Codex use `--host codex`. Use `--host all` for all supported hosts. Omit skill names to install all fourteen. The installer copies `THE_WAY.md` and creates a missing `AGENTS.md` with `Role: Rōnin`, preserving existing project instructions. Select Deshi or Kensei by editing that role line. For Claude, `CLAUDE.md` is created if missing.

Invoke `/the-scroll`, `/the-challenge`, `/the-battle-map`, `/forge-the-pipeline`, `/forge-a-contract`, `/survey-the-ground`, `/study-the-wind`, `/council-of-masters`, `/chart-the-path`, `/draw-the-blade`, `/test-the-steel`, `/sharpen-the-blade`, `/lessons-of-battle`, or optional `/the-campaign`.

## Verify source and installation
```bash
python3 scripts/sync.py --check
python3 scripts/verify.py
python3 -m unittest discover -s tests -v
```

To regenerate host adapters after changing canonical `skills/`, run `python3 scripts/sync.py` and commit all generated changes.

## Behavioral trials
```bash
python3 scripts/eval.py
python3 scripts/eval.py --execute --scenario challenge-one-question
```
The first command reports `NOT_RUN`. The second requires an authenticated local Claude CLI, installs the tested skill into an isolated temporary fixture, captures transcripts and produces a heuristic result. It **does not** run in CI; manual review is required. See [MVP acceptance](docs/MVP-ACCEPTANCE.md) and [live testing](docs/LIVE-TESTING.md).

The framework is independent of Foundation. Fabric and Azure are optional target environments.
