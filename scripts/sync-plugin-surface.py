#!/usr/bin/env python3
"""Sync Cursor + Claude plugin surface from canonical skills (Forge stays one package)."""

from __future__ import annotations

import json
import re
import shutil
import stat
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKILLS = sorted(ROOT.glob("skills/*/*/SKILL.md"))


def frontmatter(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    match = re.match(r"---\n(.*?)\n---", text, re.S)
    if not match:
        raise SystemExit(f"missing frontmatter: {path}")
    data: dict[str, str] = {}
    for line in match.group(1).splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        data[key.strip()] = value.strip()
    return data


def write_commands() -> list[str]:
    commands_dir = ROOT / "commands"
    if commands_dir.exists():
        shutil.rmtree(commands_dir)
    commands_dir.mkdir(parents=True)
    names: list[str] = []
    for skill in SKILLS:
        meta = frontmatter(skill)
        body = skill.read_text(encoding="utf-8")
        if "disable-model-invocation: true" not in body.split("---", 2)[1]:
            continue
        name = meta["name"]
        desc = meta.get("description", f"Use /{name}")
        rel = skill.parent.relative_to(ROOT).as_posix()
        out = commands_dir / f"{name}.md"
        out.write_text(
            f"---\nname: {name}\ndescription: {desc}\n---\n\n"
            f"# /{name}\n\n"
            f"Follow `{rel}/SKILL.md` and THE_WAY.md. "
            f"Keep the Forge with the skills — one package.\n",
            encoding="utf-8",
        )
        names.append(name)
    return sorted(names)


def sync_hooks_and_rules() -> None:
    hooks_dir = ROOT / "hooks"
    hooks_dir.mkdir(parents=True, exist_ok=True)
    src_hook = ROOT / "templates" / "cursor" / "hooks" / "autostart.py"
    dst_hook = hooks_dir / "autostart.py"
    shutil.copy2(src_hook, dst_hook)
    mode = dst_hook.stat().st_mode
    dst_hook.chmod(mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    (hooks_dir / "hooks.json").write_text(
        json.dumps(
            {
                "hooks": {
                    "sessionStart": [{"command": "./hooks/autostart.py"}],
                    "beforeSubmitPrompt": [{"command": "./hooks/autostart.py"}],
                }
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    rules_dir = ROOT / "rules"
    rules_dir.mkdir(parents=True, exist_ok=True)
    src_rule = ROOT / "templates" / "cursor" / "rules" / "data-warrior-autostart.mdc"
    shutil.copy2(src_rule, rules_dir / "data-warrior-autostart.mdc")


def skill_paths() -> list[str]:
    return [p.parent.relative_to(ROOT).as_posix() for p in SKILLS]


def write_cursor_plugin(skills: list[str], commands: list[str]) -> None:
    path = ROOT / ".cursor-plugin" / "plugin.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    manifest = {
        "name": "data-warrior-forge",
        "displayName": "The Data Warrior — Forge",
        "version": "0.2.0",
        "description": (
            "Data Warrior skills and Forge software factory as one package: "
            "welcome, ground the decision, then build with proof and human approve."
        ),
        "author": {"name": "Randy Archambault"},
        "homepage": "https://github.com/Rla102277/The-data-warrior-agent",
        "repository": "https://github.com/Rla102277/The-data-warrior-agent",
        "license": "MIT",
        "keywords": [
            "data-engineering",
            "skills",
            "forge",
            "data-warrior",
            "musashi",
        ],
        "category": "productivity",
        "skills": [f"./{s}" for s in skills],
        "commands": "./commands",
        "rules": "./rules",
        "hooks": "./hooks/hooks.json",
    }
    path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


def write_claude_plugin(skills: list[str]) -> None:
    path = ROOT / ".claude-plugin" / "plugin.json"
    manifest = {
        "name": "data-warrior-forge",
        "version": "0.2.0",
        "description": (
            "Data Warrior skills and Forge line for data engineers and analysts: "
            "ground the decision, then build with proof and human approve. "
            "Skills and Forge ship together."
        ),
        "author": {"name": "Randy Archambault"},
        "repository": "https://github.com/Rla102277/The-data-warrior-agent",
        "license": "MIT",
        "keywords": [
            "data-engineering",
            "skills",
            "forge",
            "musashi",
            "data-warrior",
        ],
        "skills": [f"./{s}" for s in skills],
    }
    path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    market = ROOT / ".claude-plugin" / "marketplace.json"
    market.write_text(
        json.dumps(
            {
                "name": "data-warrior",
                "owner": {"name": "Randy Archambault"},
                "metadata": {
                    "description": (
                        "The Data Warrior — skills and Forge as one Claude Code plugin."
                    ),
                    "version": "0.2.0",
                },
                "plugins": [
                    {
                        "name": "data-warrior-forge",
                        "source": ".",
                        "description": (
                            "Data Warrior skills and Forge software factory together: "
                            "welcome, ground, then build with proof."
                        ),
                    }
                ],
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )


def write_cursor_marketplace() -> None:
    """Single-plugin marketplace so the GitHub repo can be added as a Cursor marketplace."""
    path = ROOT / ".cursor-plugin" / "marketplace.json"
    path.write_text(
        json.dumps(
            {
                "name": "data-warrior",
                "owner": {"name": "Randy Archambault"},
                "metadata": {
                    "description": (
                        "The Data Warrior — skills and Forge as one Cursor plugin."
                    ),
                    "version": "0.2.0",
                },
                "plugins": [
                    {
                        "name": "data-warrior-forge",
                        "source": ".",
                        "description": (
                            "Data Warrior skills and Forge software factory together."
                        ),
                    }
                ],
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )


def main() -> None:
    assert SKILLS, "no skills found"
    commands = write_commands()
    sync_hooks_and_rules()
    skills = skill_paths()
    write_cursor_plugin(skills, commands)
    write_claude_plugin(skills)
    write_cursor_marketplace()
    print(
        f"PASS: plugin surface synced — {len(skills)} skills, "
        f"{len(commands)} commands, Cursor + Claude manifests"
    )


if __name__ == "__main__":
    main()
