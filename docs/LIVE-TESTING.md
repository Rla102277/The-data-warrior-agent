# Live testing

1. Open this repository in Cursor Agent; verify `/the-campaign` appears.
2. `/the-challenge`: present an ambiguous ingestion problem. Expect exactly one substantive question per turn, not a giant questionnaire.
3. `/the-scroll`: answer questions and verify Markdown files actually change.
4. `/the-campaign`: request incremental orders ingestion in Deshi mode. Expect inspection, plan, explicit approval, implementation and actual test evidence.
5. Interrupt; start a fresh conversation; invoke `/return-to-the-path`. Compare recovered facts with mission files.
6. Run `/council-of-masters`, `/the-sentinel`, `/prove-the-way`; inspect disagreements and unknown results.
7. Record failures in evals/LIVE_SCORECARD.md and refine the corresponding skill.

A successful structural test does not prove correct agent behavior. Do not test destructive cloud changes without permissions.
