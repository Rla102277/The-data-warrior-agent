# Live tests

Structural CI is not behavioral proof. The optional `scripts/eval.py` runs headless Claude CLI against controlled fixture repositories and saves transcript, stderr and a JSON result in `evals/runs/`. Requires a local authenticated `claude` executable. No credentials are stored here. No permission bypass.

```bash
python3 scripts/eval.py
python3 scripts/eval.py --execute --scenario challenge-one-question
```

A single question mark is only a **heuristic** for one question; inspect transcript manually. More scenarios (Scroll contradictions, role boundaries) are manual until robust grading is added. Do not claim live success without transcripts and observed outcomes.

Next tests: real data fixture for late updates, deletes and replay; cross-session Scroll persistence; Battle Map reconciliation; named-role differentiation; Cursor and Codex native invocation.
