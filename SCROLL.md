# Scroll — Data Warrior skills repo shape

## Goal
Reshape this repository so its public layout matches [mattpocock/skills](https://github.com/mattpocock/skills/tree/main). Treat [the-data-warriors-manuscript](https://github.com/Rla102277/the-data-warriors-manuscript) as the factual source for names, doctrine, and skill substance.

## Verified facts
- This repo (`the-data-warrior-agent`, `main`) is a flat fourteen-skill pack: canonical files in `skills/*/SKILL.md`, generated mirrors in `.agents/skills` and `.claude/skills`, thin `.cursor/commands`, Python `scripts/install.py`, `sync.py`, `verify.py`, `eval.py`, plus `THE_WAY.md`, role lines, and MVP gates in `docs/MVP-ACCEPTANCE.md`.
- [mattpocock/skills](https://github.com/mattpocock/skills) `main` (inspected 2026-10-19) is a skills product, not a generated-mirror installer:
  - Buckets under `skills/`: `engineering/`, `productivity/`, `misc/`, `in-progress/`, `deprecated/`.
  - Promoted skills (`engineering/`, `productivity/`) are listed in the top-level `README.md`, grouped **User-invoked** vs **Model-invoked**, and shipped from `.claude-plugin/plugin.json`.
  - Each promoted skill has a human docs page under `docs/<bucket>/`.
  - Repo law lives in `CLAUDE.md`, `SCOPE.md`, `GLOSSARY.md`, `.agents/adr/`, `.agents/invocation.md`.
  - User-invoked skills set `disable-model-invocation: true` (example: `grill-with-docs`). Model-invoked skills omit that flag (example: `tdd`).
  - Local install is a symlink script (`scripts/link-skills.sh`), with changesets for versioning. No Python sync of duplicated skill trees.
- First read (2026-10-19, earlier this session): `https://github.com/Rla102277/the-data-warriors-manuscript` returned HTTP 404 without credentials, and `git ls-remote` asked for a username. No local clone was found. **Superseded** by the second read below.
- Second read (2026-10-19, this turn): the API returns the repo as public, default branch `main`, created `2026-10-19T12:59:11Z`, pushed `2026-10-19T13:39:23Z`. `PROJECT_STATE.md` in that repo still says visibility private. Governing files read: `README.md`, `AGENTS.md`, `DECISIONS.md`, `MANUSCRIPT_ARCHITECTURE.md`, `PROJECT_STATE.md`, `planning/MIGRATION_PLAN.md`, `planning/SOURCE_CROSSWALK.md`, `archive/README.md`, and `chapters/01-earth/05-strategy-before-technology/README.md`.
- Manuscript facts that constrain this skills repo:
  - The manuscript is the canonical source of truth for the book. Git preserves content; `DECISIONS.md` and `PROJECT_STATE.md` preserve why. No chat transcript is canonical.
  - The book must stay readable without its companion software. The human is the Data Warrior; AI augments judgment.
  - Five Rings (Earth, Water, Fire, Wind, Void) are Musashi's structure. People, Tools, and Practice are modern extensions. An eight-book, 36-chapter architecture is **proposed, not approved**.
  - Named Council roles to preserve: Strategist, Architect, Engineer, Guardian, Examiner, Sensei.
  - The Living Scroll houses a challenge through its lifecycle. The Battle Map includes objectives, terrain, dependencies, actions, risks, decisions, and proof.
  - Book VII includes a proposed chapter "AI Agents and Skills". Book VIII includes "The Living Scroll" and "From Battle Map to Outcome".
  - Original DOCX drafts are not in the repo. Recovered chat drafts must not be treated as completed prose or as originals. Do not fabricate missing prose.
- Recovered December 2025 prose, read 2026-10-19 from `archive/chat-recovered/2025-12-book-rewrite/`: preface plus 17 chapters. The index in that folder says 33,504 words, rebuilt by replaying the chat's file writes. Chapter prose was written by Claude around Randy's stories. The index says details absent from Randy's own turns must be verified before reuse. The preface itself marks "The data is the noise; the structure is the truth" as what he heard, not a Musashi quotation.
- That recovered book is five books, not eight. Preface states the two demands: demand simplicity (one action, one sentence) and embrace discipline (boring, repeated execution). Ground is diagnosis before building. Water is adaptation, the 80% solution, and a sustainable pace. Fire is winning the decision, handling refusal, building capital, and walking away. Wind is ten failure patterns. Void is incentives, power, culture, and knowing when a system cannot be fixed. Each chapter is meant to end in Sword Drills. Sun Tzu is excluded. People, Tools, and Practice do not appear as books in this draft.

## Decisions
| ID | Decision | Rationale | Status | Evidence |
|---|---|---|---|---|
| D-001 | Make this repo look like mattpocock/skills. The manuscript is the factual source for warrior content. | User direction, 2026-10-19. | Accepted | This conversation. Layout evidence above. Manuscript governing files read on the second attempt. |
| D-002 | Build Pocock's kind of system, organized by the Data Warrior's eight books. | User, 2026-10-19: "a system like Matthew's following the data warrior structure." | **Superseded** by D-003 for the eight-book taxonomy. The Pocock-system half stands. | Eight book names came from proposed `MANUSCRIPT_ARCHITECTURE.md`, which the recovered prose does not use. |
| D-003 | The product is Musashi's five-ring philosophy for data engineers, built as a Matt-style skill system. User-invoked flows orchestrate. Model-invoked sword drills hold the discipline. Pipeline work is a discipline the flows call, the way Matt's `implement` calls `tdd`. | User, 2026-10-19: "a Musashi data warrior philosophy for data engineers, geared around Matt's skills, like the grill me." | Accepted | This conversation. Recovered preface and chapters 1–17. Matt's user-invoked versus model-invoked split in his README and `CLAUDE.md`. |
| D-004 | The system serves data engineers, data analysts, and neighboring roles who are starting a new project or task with an agent. It produces the steps a software factory runs, and it builds. | User, 2026-10-19. | Accepted | This conversation. Foundation Factory loop inspected in `Foundation-2.0/.cursor/skills/factory/SKILL.md`: feature, spec, build, security/naming/data-quality reviews, approve. |
| D-005 | Bring Foundation into this system and call it the Forge. | User, 2026-10-19: "bring the foundation into this and call it the forge." | **Superseded** by D-006. Foundation the product stays in its own repo and keeps its name. | The follow-up on 2026-10-19 says Foundation stays where it is as Foundation. |
| D-006 | Foundation stays in Foundation-2.0 under its own name. The thoughts of its factory merge into this skills framework. Inside this framework that loop is the Forge. | User, 2026-10-19. | **Superseded** by D-007. The user corrected this: they want the code copied in, not only the ideas. | User correction the same day. |
| D-007 | Copy Foundation into this repo. Bring Matt Pocock's skill processes into this repo as well. Foundation keeps the name Foundation. | User, 2026-10-19. | **Superseded** by D-008. | User corrected: in this repo the platform is named Forge. |
| D-008 | Implement The Forge: Matt-style command/discipline skills with a ground gate, copy Foundation-2.0 into this repo renamed Forge (`forge` CLI, `forge-line/jobs`), leave original Foundation-2.0 on disk. | Plan approved 2026-10-19. | Accepted | Implementation evidence: 30 bucketed skills, `forge doctor` ok, warrior unittest OK, pytest 69 passed. |
| D-009 | The Forge in this repo is the author's work under MIT. The "Proprietary" label was a mistaken carry-over from Foundation-2.0's pyproject, not a claim that Forge belongs to someone else. | User, 2026-10-19. | **Superseded** by D-010 for the platform copy. | License note stands for skills. |
| D-010 | Remove all Foundation/platform code from this repository. Keep only the software-factory *concept* as Forge skills and file-based jobs. Foundation stays in its own project. | User, 2026-10-19. | **Superseded** by D-011. Over-deleted the Forge runtime. | User clarification immediately after. |
| D-011 | Keep The Forge software factory in this repo (skills + `forge`/`forge-line` runtime). Do **not** bring Foundation estate knowledge (`knowledge/platform`, ops inventories, ADO Fabric estate docs, rebuild ledgers, analytics SQL estates). | User, 2026-10-19: wanted the Forge; none of the existing Foundation knowledge should have been brought in. | Accepted | Restored Forge SDK from `1eb8679` without knowledge/platform, docs/platform, rebuild, automation, dbt, .azuredevops. |

## Assumptions
- "A system like Matthew's" means his product mechanics: user-invoked versus model-invoked, a router, README catalog, plugin manifest, docs pages, and symlink install. **Accepted in D-008.**

## Contradictions
- D-002 took eight books from a proposed manuscript outline. The shipped skill buckets follow the five rings plus forge/practice/way (D-003/D-008).
- Collaboration roles remain Deshi, Rōnin, and Kensei. The manuscript's Council roles are not yet skills.
- `PROJECT_STATE.md` in the manuscript still says private; the API showed public on 2026-10-19.

## Rejected alternatives
- Use Pocock's `engineering/` and `productivity/` folders as the skill taxonomy. Rejected by D-002.
- Keep the factory as a portable step list with Foundation optional. Rejected by D-005.
- Copy Foundation estate knowledge into this repo. Rejected by D-011.
- Delete the Forge software factory runtime along with that knowledge. Rejected by D-011 (over-correction in D-010).
- Keep the product name Foundation inside this repo. Rejected.

## Acceptance tests
- [x] README lists commands and disciplines with links to each `SKILL.md`.
- [x] Plugin manifest lists promoted skills; docs pages exist under `docs/<bucket>/`.
- [x] Generated duplicate skill trees removed; `scripts/link-skills.sh` is the host install path.
- [x] Ground gate required before forge spec; `the-forge` skill encodes the line.
- [x] Warrior unittest passes locally (skills only).
- [x] Forge runtime restored without Foundation estate knowledge (D-011).
- [ ] Live host transcript for `/know-the-ground` then `/the-forge`.

## Next challenge
None for ownership of Forge vs knowledge. Next work is live host trials of `/know-the-ground` then `/the-forge` against a real target project.
