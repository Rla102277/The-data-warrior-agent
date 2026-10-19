# MVP acceptance

## Release gates
- [ ] Current commit passes GitHub Actions: skill sync, packaging checks, installer tests, SQLite pipeline fixture.
- [ ] Fresh Cursor project: installed slash command invokes the intended skill.
- [ ] Fresh Claude Code project: installed skill discovered, transcript captured.
- [ ] Scroll: one question per turn, persisted decision, contradiction supersession, cross-session resumption.
- [ ] Battle Map: real evidence and restart without invented completion.
- [ ] Role switch changes collaboration, never authorization.
- [ ] Agent implements a pipeline independently and passes duplicate, out-of-order, delete and rollback tests.

## What tests mean
SQLite reference tests establish **fixture correctness**, not that a model used a skill successfully. CI structural checks do not prove host behavior. Only actual host transcripts and independent grading can close behavioral gates.

## Release claim
Call this an **MVP candidate** until the gates above are evidenced. Do not call it a deployed data agent service.
