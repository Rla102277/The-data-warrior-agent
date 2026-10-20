"""Install selected bucketed skills into a target project for one or more hosts."""
from pathlib import Path
import argparse, shutil, stat

ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument("target")
p.add_argument("skills", nargs="*")
p.add_argument("--host", choices=("cursor", "claude", "codex", "all"), default="cursor")
p.add_argument("--overwrite", action="store_true")
a = p.parse_args()
target = Path(a.target).expanduser().resolve()
if not target.is_dir():
    p.error("Target directory must exist")

available = {x.parent.name: x for x in (ROOT / "skills").glob("*/*/SKILL.md")}
selected = a.skills or sorted(available)
for name in selected:
    if name not in available:
        p.error("Unknown skill " + name)
hosts = ("cursor", "claude", "codex") if a.host == "all" else (a.host,)


def copy(src: Path, dst: Path, *, executable: bool = False) -> None:
    if dst.exists() and not a.overwrite:
        print("SKIP existing", dst)
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    if executable:
        mode = dst.stat().st_mode
        dst.chmod(mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    print("INSTALLED", dst)


copy(ROOT / "THE_WAY.md", target / "THE_WAY.md")
welcome_src = ROOT / "templates" / "WELCOME.md"
if welcome_src.is_file():
    copy(welcome_src, target / "WELCOME.md")

for host in hosts:
    folder = {"cursor": ".agents/skills", "claude": ".claude/skills", "codex": ".agents/skills"}[host]
    for name in selected:
        src = available[name]
        copy(src, target / folder / name / "SKILL.md")
        if host == "cursor":
            command = target / ".cursor/commands" / f"{name}.md"
            if not command.exists() or a.overwrite:
                command.parent.mkdir(parents=True, exist_ok=True)
                command.write_text(
                    f"# /{name}\n\nFollow `.agents/skills/{name}/SKILL.md` and THE_WAY.md.\n"
                )
                print("INSTALLED", command)

# Cursor autostart: hooks + always-on rule (welcome + level ask)
if "cursor" in hosts or a.host == "all":
    cursor_tpl = ROOT / "templates" / "cursor"
    copy(cursor_tpl / "hooks.json", target / ".cursor" / "hooks.json")
    copy(
        cursor_tpl / "hooks" / "autostart.py",
        target / ".cursor" / "hooks" / "autostart.py",
        executable=True,
    )
    copy(
        cursor_tpl / "rules" / "data-warrior-autostart.mdc",
        target / ".cursor" / "rules" / "data-warrior-autostart.mdc",
    )

config = target / "AGENTS.md"
agents_body = """# Agent project instructions

Role: Rōnin

Read THE_WAY.md and WELCOME.md. Roles affect collaboration, never permissions.

## On project start
When this folder is opened or a new agent chat starts:
1. Present WELCOME.md (welcome + guiding principles).
2. Ask the collaboration **level** with a numbered menu (Deshi / Rōnin / Kensei) and wait.
3. Update the Role line above to match. Roles never grant permissions.
4. Finish **all** `/setup-the-forge` menus (A–G, one per turn), including asking if there are files to upload/attach — do not stop after `repo_host` alone.
5. Then keep going through `/know-the-ground` questions **1 of 6 through 6 of 6**. At Deshi, teach between questions. Never end a turn without the next numbered question while the gate is incomplete.
6. Do not assume GitHub, Azure DevOps, or any platform.
"""
if not config.exists():
    config.write_text(agents_body)
    print("INSTALLED", config)
elif a.overwrite:
    text = config.read_text()
    if "1 of 6 through 6 of 6" not in text:
        config.write_text(
            text.rstrip()
            + "\n\n## On project start\n"
            "Present WELCOME.md, ask level, finish all setup menus, "
            "then ground questions 1–6 (Deshi teaches between). "
            "Never stop mid-gate without the next numbered question.\n"
        )
        print("UPDATED", config)
