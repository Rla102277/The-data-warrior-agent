"""Install selected bucketed skills into a target project for one or more hosts."""
from pathlib import Path
import argparse, shutil, sys

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


def copy(src, dst):
    if dst.exists() and not a.overwrite:
        print("SKIP existing", dst)
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
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

config = target / "AGENTS.md"
agents_body = """# Agent project instructions

Role: Rōnin

Read THE_WAY.md and WELCOME.md. Roles affect collaboration, never permissions.

## On project start
When this project is opened or the human starts a new thread here:
1. Present the welcome and guiding principles from WELCOME.md (plain language).
2. If the Scroll has no setup / no `repo_host`, guide them to `/setup-the-forge` — menu-driven, one menu per turn.
3. Do not assume GitHub, Azure DevOps, or any platform.
"""
if not config.exists():
    config.write_text(agents_body)
    print("INSTALLED", config)
elif a.overwrite and "On project start" not in config.read_text():
    # Preserve custom Role lines; append start block once when overwriting install.
    text = config.read_text()
    if "On project start" not in text:
        config.write_text(text.rstrip() + "\n\n## On project start\n"
                          "Present WELCOME.md, then `/setup-the-forge` if `repo_host` is missing.\n")
        print("UPDATED", config)
