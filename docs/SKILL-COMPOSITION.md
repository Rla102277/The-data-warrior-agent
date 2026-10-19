# Composition and discovery

**One skill, one job.** Skills are invoked directly by name. A skill may reference another skill's canonical procedure; avoid copying long instructions.

- `the-interrogation` is a shared internal method.
- `the-challenge` is the stateless conversational entry point.
- `the-scroll` is the stateful conversational entry point and **houses The Challenge**.
- `the-battle-map` is optional progress memory, not a mandatory precondition.
- `the-campaign` is optional coordination for large work.

When installing The Challenge or The Scroll, the installer automatically includes The Interrogation. Installed `skills/` paths remain valid. Cursor commands are thin entry points; host-native mirrors match canonical skill files.

**Discovery:** Recommend a single matching skill from the user request; don't require the user to memorize names or invoke Campaign first. If a skill needs another, load only that dependency.

**Maintenance:** Change canonical skill content and both host mirrors in one commit. Run `scripts/verify.py` and installation tests. Structural checks don't establish model behavior.
