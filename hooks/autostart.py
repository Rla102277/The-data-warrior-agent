#!/usr/bin/env python3
"""Inject Data Warrior welcome + level ask on session / first prompt."""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path


def project_root() -> Path:
    env = os.environ.get("CURSOR_PROJECT_DIR") or os.environ.get("CLAUDE_PROJECT_DIR")
    if env:
        return Path(env)
    return Path.cwd()


def welcome_text(root: Path) -> str:
    path = root / "WELCOME.md"
    if path.is_file():
        return path.read_text(encoding="utf-8").strip()
    return (
        "Welcome — The Data Warrior\n"
        "Technical completion is not strategic success.\n"
        "Know the decision before the build. One action in one sentence.\n"
        "You stay in charge."
    )


def build_context(root: Path) -> str:
    return f"""# AUTOSTART — Data Warrior (project / folder open)

This conversation just started in a Data Warrior project. On your **first assistant reply**, before other work:

1. Present the welcome and guiding principles (from WELCOME.md below), in plain language.
2. Immediately ask the collaboration **level** with this menu and wait for a number:

```text
How should we work together on this project?
Reply with a number:
1) Deshi — Apprentice: teach me, explain tradeoffs, confirm before big edits
2) ★ Rōnin — Practitioner: act within the agreed scope and report outcomes
3) Kensei — Master: anticipate system-wide risk; still no extra permissions
```

3. Update `AGENTS.md` Role line to match their pick (styles only — never grant permissions).
4. Continue **every** `/setup-the-forge` menu (A–G), one per turn — include asking if they have files to upload/attach. Do not stop after repo_host alone.
5. When the last setup menu is answered, start `/know-the-ground` **Ground question 1 of 6** in that same reply. Keep going through all six questions. At Deshi, teach briefly between each, then ask the next.
6. Never end a turn with only “setup is done” / “project is empty” and no next numbered question.

Do not assume GitHub, Azure DevOps, or any platform.
Do not skip the level menu on the first reply.

---
WELCOME.md
---
{welcome_text(root)}
"""


def main() -> int:
    raw = sys.stdin.read()
    try:
        payload = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        payload = {}

    event = str(payload.get("hook_event_name") or "")
    root = project_root()
    context = build_context(root)

    # sessionStart: always inject
    if event == "sessionStart" or (not event and "session_id" in payload and "prompt" not in payload):
        print(json.dumps({"additional_context": context}))
        return 0

    # beforeSubmitPrompt: inject once per conversation (Agents Window workaround)
    session = str(
        payload.get("session_id")
        or payload.get("conversation_id")
        or payload.get("generation_id")
        or ""
    )
    marker_dir = root / ".cursor" / ".welcome_sessions"
    marker_dir.mkdir(parents=True, exist_ok=True)
    if session:
        marker = marker_dir / f"{session}.done"
        if marker.exists():
            print(json.dumps({"continue": True}))
            return 0
        marker.write_text("1", encoding="utf-8")

    # Forum-supported field; also keep continue for schema compatibility
    print(json.dumps({"continue": True, "additional_context": context}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
