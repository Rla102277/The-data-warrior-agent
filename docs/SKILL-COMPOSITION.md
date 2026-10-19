# Skill design

Canonical files live at `skills/<bucket>/<name>/SKILL.md`. Commands set `disable-model-invocation: true`. Disciplines omit that flag. A command never calls another command.

`scripts/link-skills.sh` symlinks into local harness directories. `scripts/sync.py --check` fails if generated mirror trees reappear. `scripts/verify.py` checks packaging, the ground gate, and the plugin manifest.

Ground gate before any forge spec: decision, owner, success, grain, source of truth, cost of being wrong, single action in one sentence.
