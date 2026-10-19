# Agent architecture

Foundation agents are **clients of the SDK**. They do not replace policies, discovery, or quality engines.

## Thin set (Cursor)

| Agent | File | Writes |
|---|---|---|
| Factory Director | `.cursor/skills/factory/SKILL.md` | owns `job.json` stage via CLI/engine |
| spec-writer | `.cursor/agents/spec-writer.md` | `spec.md` |
| builder | `.cursor/agents/builder.md` | code + `build.md` |
| reviewer-security | `.cursor/agents/reviewer-security.md` | `review-security.md` |
| reviewer-naming | `.cursor/agents/reviewer-naming.md` | `review-naming.md` |
| reviewer-data-quality | `.cursor/agents/reviewer-data-quality.md` | `review-data-quality.md` |
| approver | `.cursor/agents/approver.md` | `decision.md` |

Expand specialist roles only when tools, permissions, and evidence requirements diverge.

## Independence

Builders must not certify production. Reviewers read evidence files. Approver escalates production Fabric changes.
