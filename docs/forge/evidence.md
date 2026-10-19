# Forge evidence

Approval reads recorded executions and structured reviews. A Markdown line that says `VERDICT: PASS`, or a note that says the tests passed, is not evidence.

## Trust boundary

`forge job approve --authorized` is an operator attestation on this host. It is not cryptographic proof of identity. Production execution still depends on the OS user, repository permissions, and platform policy. The default profile is `forge-default`. No vendor platform is bundled. Tools are chosen after the ground is known.

## What a real test is

`forge job test` runs an explicit argument array with `shell=False`. It stores the command, working directory, timestamps, exit code, stdout, stderr, and SHA-256 hashes under the job directory. Exit code 0 is taken from the process, never from the words in stdout.

Synthetic demo evidence (`advance_happy_path`, `attach_demo_evidence`) is marked `synthetic: true` and cannot make a real job deployment-ready. `create_job` cannot turn demo mode on.

## Reviews

Keep `review-security.md`, `review-naming.md`, and `review-data-quality.md`. Also record `reviews/<type>.json` with reviewer, verdict (`PASS` or `CHANGES`), build id, and evidence ids. Three reviews from one reviewer are perspectives, not independent reviewers. A review of an earlier build is stale after rework.

## Commands

```bash
forge job test --job-id "$JOB" -- python -c 'import sys; sys.exit(1)'
forge job evidence --job-id "$JOB"
forge job review --job-id "$JOB" --review-type security --reviewer examiner --verdict PASS --finding "no secrets in the fixture"
forge job verify --job-id "$JOB"
forge job approve --job-id "$JOB" --authorized
```

`verify` prints every missing, stale, failed, or tampered check and exits 1 when the job is not approval-ready. The CLI does not invent a passing test or a PASS review.

## Local-orders acceptance (observed 2026-10-19)

Command:

```bash
python demos/local_orders/accept_lifecycle.py
```

Host: local macOS, Python 3.11.9 (`/Users/randy/.pyenv/versions/3.11.9/bin/python`). This run did not call a cloud platform.

Observed before the successful pending job:

| Check | Result |
|---|---|
| `python -c 'import sys; sys.exit(1)'` | exit 1, verification blocked (`latest required test failed`) |
| Passing local-orders transform (`order_count == 12`, `gross_revenue == 1250.5`, `quarantine_count == 2`) | exit 0, `synthetic: false` |
| Markdown `VERDICT: PASS` without a review record | blocked (`fake PASS text`) |
| Security review `CHANGES` | blocked |
| Data-quality review file removed | blocked |
| Stdout edited after the run | blocked (`tampered test artifact`) |
| `forge job verify` after the evidence was restored | exit 0 |
| `forge job approve` without `--authorized` | exit 2, stage `CANCELLED`, not `DEPLOYMENT_READY` |

The successful job stopped at `APPROVAL_PENDING`. Reviews were three perspectives from `acceptance-examiner`, not three independent reviewers (`reviews_independent: false`).

Same-day suite on this machine: `python3 scripts/verify.py` passed (30 skills), `python3 -m unittest discover -s tests/warrior -v` passed (12 tests), `python -m pytest` passed (95 tests). GitHub Actions on the pull request is the CI result; do not treat this local run as that check.

## Not proven here

This acceptance did not deploy anywhere, did not exercise a second human reviewer, and did not prove host identity beyond the local OS user who ran the process.
