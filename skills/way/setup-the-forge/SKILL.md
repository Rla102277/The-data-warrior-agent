---
name: setup-the-forge
description: Use when setting up a repository once to configure Scroll path, forge job folder, proof location, and autonomy defaults.
disable-model-invocation: true
---

# Setup The Forge

Ask **exactly one question per turn** until these are recorded in `SCROLL.md` under a decision id:

1. Where should `SCROLL.md` live (repo root unless they say otherwise).
2. Where forge jobs live (default `forge-line/jobs/`).
3. Where proof artifacts and review rounds live (default inside each job folder).
4. Autonomy default (Level 2: build and test in isolation; never auto-approve production).
5. Whether a `forge` CLI is available in this repo (yes when the platform package is installed).

After answers, write a short setup block into `SCROLL.md` and create missing empty directories only. Do not start a job.

Follow project instructions and THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
