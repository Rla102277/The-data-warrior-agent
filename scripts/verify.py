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

ground = (ROOT / "skills/ground/know-the-ground/SKILL.md").read_text().lower()
assert "single action" in ground

forge = (ROOT / "skills/forge/the-forge/SKILL.md").read_text().lower()
assert "know-the-ground" in forge
assert "verdict" in forge

plugin = ROOT / ".claude-plugin/plugin.json"
assert plugin.is_file(), "missing .claude-plugin/plugin.json"
manifest = json.loads(plugin.read_text())
assert "skills" in manifest and len(manifest["skills"]) >= 10

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
    "ground gate, forge loop, plugin manifest"
)
