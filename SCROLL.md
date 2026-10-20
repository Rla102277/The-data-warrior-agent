# Scroll — Data Warrior skills repo shape

## Goal
Ship a companion skill system and Forge factory that rehearse [The Data Warrior's Manuscript](https://github.com/Rla102277/the-data-warriors-manuscript) against real work — without becoming the measure of success. Layout matches [mattpocock/skills](https://github.com/mattpocock/skills/tree/main). The manuscript is the factual source for names, doctrine, and mission.

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
| D-012 | Align this repo's identity and ground gate to the manuscript mission/vision: technical completion ≠ strategic success; human is the Warrior; two demands (simplicity + discipline); Forge is Tools/instrument; book readable without software; measure decisions changed. | User, 2026-10-19: "reread the manuscript… Align to my mission and vision." | Accepted | Re-read preface, Ch1 working draft, editorial master plan, AGENTS invariants, MASTER_BRIEF philosophy. Updated THE_WAY, README, SCOPE, CLAUDE, AGENTS, know-the-ground, the-forge, ask-the-warrior. |
| D-013 | Real Forge approval requires a recorded local test execution and three structured reviews bound to that build. Synthetic demo evidence cannot qualify a real job. `--authorized` is an operator attestation, not cryptographic identity. | User, 2026-10-19: finish the Forge evidence system. | Accepted | `forge/line/evidence.py`, adversarial tests, local-orders acceptance stopped at `APPROVAL_PENDING`. |
| D-014 | Match the manuscript parity contract of 2026-10-19: five rings plus modern extensions, Council as perspectives, Scroll/Battle Map/Chronicle fields, and an honest limit that host behavioral parity is not yet passed. | User, 2026-10-19: manuscript was updated; match theory and practice. | Accepted | Manuscript `AGENT_PARITY_CONTRACT.md` at `16c16a2`. Agent `docs/PARITY.md`. README no longer claims textual PASS notes satisfy the evidence gate. |
| D-015 | Do not ship a vendor platform. Microsoft Fabric is not a default profile, adapter, discovery path, or dependency. Tools are recorded on the ground and brought in only when the single action needs them. | User, 2026-10-19: remove all Fabric stuff; it belongs to know-the-ground and tools as needed. | Accepted | Removed `forge/fabric`, the Fabric discovery adapter, `fabric-first-foundation`, the `fabric` extra, and Fabric MCP servers. |
| D-016 | `/setup-the-forge` must ask where the code lives (GitHub, Azure DevOps, etc.) in plain language and record `repo_host` on the Scroll. Do not assume GitHub. User-facing prompts stay non-technical. | User, 2026-10-20: ask for repo type; prompts non-technical friendly. | Accepted | Friendly ask text in setup-the-forge and know-the-ground; Scroll still stores `repo_host`. |
| D-017 | Project start is menu-driven: welcome + guiding principles, then numbered menus (one per turn). Install drops `WELCOME.md`; `AGENTS.md` requires welcome on first thread. | User, 2026-10-20: menu driven; welcome and guiding principles when project started. | Accepted | `templates/WELCOME.md`, setup-the-forge Turn 0 + menus A–F, install.py. |
| D-018 | On folder/chat open, autostart welcome and ask collaboration level (Deshi/Rōnin/Kensei) via Cursor hooks + always-on rule; then setup menus. | User, 2026-10-20: on project open autostart welcome and ask level. | Accepted | `templates/cursor/hooks`, `data-warrior-autostart.mdc`, install copies into targets. |
| D-019 | Setup and ground interviews keep going: finish every setup menu, then ground questions 1–6 without stopping mid-gate. Deshi teaches between questions; every incomplete turn ends with the next numbered ask. | User, 2026-10-20: questions need to keep going; Deshi was stopping after one. | Accepted | know-the-ground / grounding / setup-the-forge keep-going rules. |
| D-020 | Skills and Forge stay one package; first-class install is Cursor plugin + Claude plugin (`data-warrior-forge`), not a skills-only split. | User, 2026-10-20: keep forge together; live as cursor plugin and claude plugin. | Accepted | `.cursor-plugin/`, `.claude-plugin/`, `scripts/sync-plugin-surface.py`, `docs/INSTALL-PLUGINS.md`. |
| D-021 | Cursor “install today” is a **copy** into `~/.cursor/plugins/local` (`install-cursor-local.sh`). Out-of-tree symlinks are skipped by Cursor. Official Cursor Marketplace listing is not available until submitted. | User, 2026-10-20: install today doesnt add up. | Accepted | Rewrote INSTALL-PLUGINS.md; removed false symlink / personal GitHub marketplace claims. |

## Assumptions
- "A system like Matthew's" means his product mechanics: user-invoked versus model-invoked, a router, README catalog, plugin manifest, docs pages, and symlink install. **Accepted in D-008.**
- Manuscript mission for this companion: close the strategic-discipline gap for analysts/executives/managers who need one action, not more ceremony. **Accepted in D-012.**

## Contradictions
- D-002 took eight books from a proposed manuscript outline. The shipped skill buckets follow the five rings plus forge/practice/way (D-003/D-008), which matches Musashi five + Tools/Practice extensions named in the manuscript architecture proposal.
- Collaboration roles remain Deshi, Rōnin, and Kensei. The manuscript's Council roles are named in THE_WAY as perspectives, not yet skills.
- `PROJECT_STATE.md` in the manuscript still says private; the API showed public on 2026-10-19.
- Recovered Dec 2025 book is five rings; eight-book architecture remains proposed in the manuscript `DECISIONS.md`.

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
- [x] Identity docs lead with manuscript mission; Forge positioned as Tools companion (D-012).
- [x] Ground gate matches Way questions + single-action demand (D-012).
- [x] Real jobs reject fabricated, stale, tampered, and synthetic evidence before approval (D-013). Local acceptance observed; CI still has to run on the pull request.
- [x] No vendor platform is bundled. Tool choice follows the ground (D-015).
- [x] Setup asks for repo host / SCM and records `repo_host` (D-016).
- [x] Project start: welcome, principles, numbered menus (D-017).
- [x] Autostart welcome + level ask on folder/chat open (D-018).
- [x] Setup + ground keep going through all steps; Deshi teaches between (D-019).
- [x] First-class Cursor + Claude plugins; Forge stays with skills (D-020).
- [x] Honest Cursor local install path (copy, not out-of-tree symlink) (D-021).
- [ ] Live host transcript for `/know-the-ground` then `/the-forge` that stops if the decision is missing.
- [ ] Optional: Council-perspective disciplines when manuscript People book is approved.

## Next challenge
Prove the mission in a live host trial: `/know-the-ground` refuses a tool-first ask, then `/the-forge` only after one action is on the Scroll.
