# Agent parity with the manuscript

Doctrine: [the-data-warriors-manuscript](https://github.com/Rla102277/the-data-warriors-manuscript) `manuscript/AGENT_PARITY_CONTRACT.md` and `manuscript/AGENT_ALIGNMENT_CANON.md`, read 2026-10-19 after `16c16a2`.

The manuscript explains why. This repository executes the parts it can check. The book must still stand alone.

## What matches

| Manuscript idea | What this repo actually does |
|---|---|
| Technical completion is not strategic success | `THE_WAY.md`; Forge refuses a build until the ground gate is on the Scroll |
| Two demands: one action, and real execution | `/know-the-ground`; `forge job test` records the process exit code |
| Five rings plus People, Tools, Practice | Skill buckets. Forge is Tools, not a sixth original ring |
| Council perspectives, not six agents | Named in `THE_WAY.md`. Security, naming, and data-quality files use Guardian, Architect, and Examiner as lenses |
| Deshi / Rōnin / Kensei are styles, not permissions | `THE_WAY.md`, `AGENTS.md` |
| Living Scroll houses the challenge | `skills/practice/the-scroll/SKILL.md` |
| Battle Map holds objective, terrain, dependencies, actions, risks, decisions, proof | `skills/practice/the-battle-map/SKILL.md` |
| Chronicle | `skills/forge/lessons-of-battle/SKILL.md` writes `CHRONICLE.md` only when a lesson is worth keeping |
| Human approval, not self-approval | `forge job approve`; `--authorized` is an attestation, not identity |
| Synthetic demo is not production proof | Explicit demo mode only. A real job rejects synthetic, stale, tampered, and prose-only evidence |

## Chapter map

Every row names a skill or law that exists in this repo. Existence is not a live host transcript.

| Chapters | Entry |
|---|---|
| 1 The Way | `THE_WAY.md` |
| 2 Know Your Terrain | `/know-the-ground`, `grounding` |
| 3 Establish the Foundation | `simplicity`, `survey-the-ground` (scope and terrain, not a workplace estate) |
| 4 Truth, Trust, and Data | `grounding`, `the-contract` |
| 5 Strategy Before Technology; 27 The Sword Is Not the Warrior | `tool-choice` |
| 6 The Formless Practitioner | `/adapt` |
| 7 Architectures That Evolve | `the-pivot`, `study-the-wind` |
| 8 Flow of Information; 28 Engineering Disciplines | `the-pipeline`, `the-contract`, `test-the-steel` |
| 9 Learning and Unlearning | `ship-the-eighty` |
| 10 Entering the Battle; 23 Leadership and Service | `/win-the-room` |
| 11 The Battle Map; 34 From Battle Map to Outcome | `the-battle-map` |
| 12 Execution Under Pressure | `/the-forge`, `draw-the-blade` |
| 13 Decisions and Tradeoffs | `/to-spec`, `chart-the-path` |
| 14 Knowing When to Stop | `/the-forge` stop rule; `forge job verify` / `approve` |
| 15 Know the Other Schools | `study-the-wind` |
| 16 Challenge Assumptions; 21 Intuition; 32 Training Through Challenges | `the-challenge` |
| 17 The Art of the Adversary | `wind-patterns`, `test-the-steel` |
| 18 Organizational Resistance | `/name-the-wind`, `/win-the-room` |
| 19 Seeing What Is Not There; 20 Judgment Beyond Metrics | `/see-the-void`, `void-sight` |
| 22 Mastery in the Age of AI; 36 The Never-Ending Way | `THE_WAY.md` |
| 24 The Council; 26 Developing Other Warriors | `THE_WAY.md` only. No Council skills |
| 25 Collaboration and Conflict | `the-scroll` |
| 29 AI Agents and Skills | `/ask-the-warrior` |
| 30 Governance by Design | `review-the-work`, `forge job verify` |
| 31 Building the Living System | `/setup-the-forge`, `/the-forge` |
| 33 The Living Scroll | `the-scroll` |
| 35 Reflection and the Chronicle | `lessons-of-battle` |

## What was executed

On 2026-10-19, local checks that match the contract's evidence rules:

- Unit tests in `tests/unit/test_evidence_gates.py` reject a missing test, a failed test, missing stdout, a tampered artifact, cross-job evidence, a stale review, a `CHANGES` verdict, a missing data-quality review, fake `VERDICT: PASS` text, synthetic evidence on a real job, approval without authorization, and a direct jump to deployment-ready.
- `python demos/local_orders/accept_lifecycle.py` ran a failing command (exit 1), then a real local-orders check (exit 0), then blocked on fake PASS text, a `CHANGES` review, a missing review, and a tampered file. The successful job stopped at `APPROVAL_PENDING`.
- `pytest` (95), warrior tests (12), and `scripts/verify.py` passed on that machine. GitHub Actions `validate` passed on pull request 4 before merge.

## What is not passed

- No live host transcript of `/know-the-ground` then `/the-forge` on a fresh project.
- No second human reviewer. Same-agent reviews stay labeled as perspectives.
- No vendor platform is bundled, and there is no proof of cryptographic identity.
- Chapter prose, Sword Drills, and publication readiness belong to the manuscript. This repo does not claim those are done.

**Verdict:** vocabulary and the enforceable factory path match the 2026-10-19 contract. Behavioral parity across hosts is open. Do not mark it passed without a transcript.
