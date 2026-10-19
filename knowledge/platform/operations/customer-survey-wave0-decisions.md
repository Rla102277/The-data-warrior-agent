# Customer Survey Wave 0 decisions

**Signed:** 2026-09-03  
**Workspace:** Foundation Development only  
**Signer:** Randy (this turn)

These four choices are closed. Later waves follow them.

| # | Decision | Choice |
|---|---|---|
| 1 | Rating scale | Keep 0-10 for all Rating questions and wire it. Status is APPROVED, not provisional. |
| 2 | Minimum sample size | Keep n = 30. The Metrics lexicon states why. |
| 3 | VOC classifier | Approved as keyword rules (`KEYWORD_RULES`). Not a language model. Wave 3 is a plan only. |
| 4 | Comment access | As is. Redacted text on the VOC page. No buyer email or phone on VOC or extracts. Hidden Comments stay behind Show details. Raw OBT access unchanged. |

## Why n = 30 (approved wording)

The statistical layer publishes a normal-approximation 95% CI (`mean +/- 1.96 * sd / sqrt(n)`) and a peer z-score. Those formulas assume the sample mean is close to normal. n = 30 is the conventional floor for that approximation. Below 30, z-score and CI are suppressed (MET vs SUPPRESSED). It is not a Green Brick scientific constant. Changing it changes who can be ranked.

## Why 0-10 is wired

Observed ratings on Rating questions sit on a 0-10 instrument. Wave 0 keeps that as the approved map for all 48 Rating questions, forward scored, not reverse scored, until a later signed change. Normalized score is `(rating - 0) / (10 - 0) * 100`.

## What this does not approve

- Fabric AISQL or Azure OpenAI for comments (Wave 3 plan only)
- VOC or analytics refresh schedules
- Operations production copy or cutover
- Replacing official category % measures
- Turning on stabilized (shrunken) scores
