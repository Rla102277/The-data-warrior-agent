"""Validate skill packaging for the bucketed Data Warrior / Forge layout."""
from pathlib import Path
import json, re, sys

ROOT = Path(__file__).resolve().parents[1]
skills = sorted(ROOT.glob("skills/*/*/SKILL.md"))
assert len(skills) >= 20, f"Expected bucketed skills; found {len(skills)}"

commands = []
disciplines = []
for path in skills:
    body = path.read_text(encoding="utf-8")
    match = re.match(
        r"---\nname: ([a-z0-9-]+)\ndescription: ([^\n]+)\n(?:disable-model-invocation: true\n)?---",
        body,
    )
    assert match, f"Invalid skill frontmatter: {path}"
    name, desc = match.groups()
    assert name == path.parent.name, (name, path)
    assert desc.startswith(("Use when ", "Use after ", "Use to ")), (name, desc)
    assert len(desc) >= 45, (name, "description too vague")
    assert len(body.strip()) > len(desc) + 70, (name, "empty skill")
    if "disable-model-invocation: true" in body.split("---", 2)[1]:
        commands.append(name)
    else:
        disciplines.append(name)

required_commands = {
    "ask-the-warrior",
    "setup-the-forge",
    "know-the-ground",
    "to-spec",
    "to-steps",
    "the-forge",
    "adapt",
    "win-the-room",
    "name-the-wind",
    "see-the-void",
}
missing = required_commands - set(commands)
assert not missing, f"Missing user-invoked commands: {sorted(missing)}"

way = (ROOT / "THE_WAY.md").read_text(encoding="utf-8")
for role in ("Deshi", "Rōnin", "Kensei"):
    assert role in way
assert "Forge" in way or "forge" in way
assert "not six agents" in way
parity = (ROOT / "docs/PARITY.md").read_text(encoding="utf-8")
assert "Behavioral parity across hosts is open" in parity

scroll = (ROOT / "skills/practice/the-scroll/SKILL.md").read_text().lower()
assert "question per turn" in scroll and "superseded" in scroll

ground_raw = (ROOT / "skills/ground/know-the-ground/SKILL.md").read_text()
ground = ground_raw.lower()
assert "single action" in ground
assert "repo_host" in ground or "repo host" in ground
assert "ground question" in ground
assert "of 6" in ground
assert "deshi" in ground
assert "do not stop" in ground or "keep going" in ground

setup_raw = (ROOT / "skills/way/setup-the-forge/SKILL.md").read_text()
setup = setup_raw.lower()
assert "repo_host" in setup
assert "azure devops" in setup or "azure_devops" in setup
assert "github" in setup
assert "welcome" in setup
assert "guiding principles" in setup
assert "reply with a number" in setup
assert "Menu Level" in setup_raw or "How should we work together" in setup_raw
assert "files to upload" in setup or "files to share" in setup
assert "files_to_upload" in setup
welcome = ROOT / "templates" / "WELCOME.md"
assert welcome.is_file(), "missing templates/WELCOME.md"
assert "guiding principles" in welcome.read_text().lower()
hooks = ROOT / "templates" / "cursor" / "hooks.json"
assert hooks.is_file(), "missing templates/cursor/hooks.json"
assert "sessionStart" in hooks.read_text()
autostart = ROOT / "templates" / "cursor" / "hooks" / "autostart.py"
assert autostart.is_file(), "missing templates/cursor/hooks/autostart.py"
assert "How should we work together" in autostart.read_text()
rule = ROOT / "templates" / "cursor" / "rules" / "data-warrior-autostart.mdc"
assert rule.is_file(), "missing data-warrior-autostart.mdc"
assert "alwaysApply: true" in rule.read_text()

forge = (ROOT / "skills/forge/the-forge/SKILL.md").read_text().lower()
assert "know-the-ground" in forge
assert "verdict" in forge

claude_plugin = ROOT / ".claude-plugin/plugin.json"
assert claude_plugin.is_file(), "missing .claude-plugin/plugin.json"
claude_manifest = json.loads(claude_plugin.read_text())
assert "skills" in claude_manifest and len(claude_manifest["skills"]) >= 10
assert (ROOT / ".claude-plugin/marketplace.json").is_file()

cursor_plugin = ROOT / ".cursor-plugin/plugin.json"
assert cursor_plugin.is_file(), "missing .cursor-plugin/plugin.json"
cursor_manifest = json.loads(cursor_plugin.read_text())
assert cursor_manifest.get("name") == "data-warrior-forge"
assert len(cursor_manifest.get("skills") or []) >= 10
assert cursor_manifest.get("hooks")
assert cursor_manifest.get("commands")
assert cursor_manifest.get("rules")
assert (ROOT / ".cursor-plugin/marketplace.json").is_file()
assert (ROOT / "hooks" / "hooks.json").is_file()
assert (ROOT / "hooks" / "autostart.py").is_file()
assert (ROOT / "rules" / "data-warrior-autostart.mdc").is_file()
cmd_files = list((ROOT / "commands").glob("*.md")) if (ROOT / "commands").is_dir() else []
assert len(cmd_files) == len(commands), (
    f"commands/ out of sync ({len(cmd_files)} files vs {len(commands)} user-invoked); "
    "run python3 scripts/sync-plugin-surface.py"
)

# No flat leftover skills at skills/*/SKILL.md
flat = list(ROOT.glob("skills/*/SKILL.md"))
assert not flat, f"Flat skills remain: {flat}"

# Generated host mirrors must not be hand-maintained duplicates of the tree
assert not (ROOT / ".agents/skills").exists() or not any((ROOT / ".agents/skills").rglob("SKILL.md")), (
    "Remove generated .agents/skills mirrors; use scripts/link-skills.sh"
)

print(
    f"PASS: {len(skills)} bucketed skills "
    f"({len(commands)} commands, {len(disciplines)} disciplines), "
    "ground gate, forge loop, Cursor + Claude plugins"
)
