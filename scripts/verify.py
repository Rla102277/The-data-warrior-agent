"""Structural verification; does not test live agent behavior."""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
CANONICAL = ROOT / "skills"
names = sorted(p.parent.name for p in CANONICAL.glob("*/SKILL.md"))
assert len(names) == 15, f"Expected 15 canonical skills, found {len(names)}"
for name in names:
    body = (CANONICAL / name / "SKILL.md").read_text(encoding="utf-8")
    assert re.search(r"(?m)^name: " + re.escape(name) + r"$", body), name
    assert "description:" in body, name
    for host in (".agents/skills", ".claude/skills"):
        mirror = ROOT / host / name / "SKILL.md"
        assert mirror.read_text(encoding="utf-8") == body, (name, host)
    assert (ROOT / ".cursor/commands" / f"{name}.md").is_file(), name
way = (ROOT / "THE_WAY.md").read_text(encoding="utf-8")
for role in ("Deshi", "Rōnin", "Kensei"):
    assert role in way, role
for name in ("the-challenge", "the-scroll"):
    assert "the-interrogation" in (CANONICAL / name / "SKILL.md").read_text(), name
assert "BATTLE_MAP.md" in (CANONICAL / "the-battle-map" / "SKILL.md").read_text()
assert (ROOT / "examples/scroll/SCROLL.md").is_file()
assert (ROOT / "examples/battle-map/BATTLE_MAP.md").is_file()
scenarios = json.loads((ROOT / "evals/scenarios.json").read_text())
assert len(scenarios) >= 8
assert len({x["id"] for x in scenarios}) == len(scenarios)
print(f"PASS: {len(names)} canonical skills, host mirrors, named roles, shared interrogation, Battle Map, {len(scenarios)} trials")
