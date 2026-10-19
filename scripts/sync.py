"""Compatibility shim: mirrors are no longer generated. Use link-skills.sh."""
from pathlib import Path
import argparse

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--check", action="store_true")
args = parser.parse_args()
skills = list(ROOT.glob("skills/*/*/SKILL.md"))
if not skills:
    raise SystemExit("No bucketed skills found under skills/*/*/SKILL.md")
mirrors = list((ROOT / ".agents/skills").rglob("SKILL.md")) if (ROOT / ".agents/skills").exists() else []
mirrors += list((ROOT / ".claude/skills").rglob("SKILL.md")) if (ROOT / ".claude/skills").exists() else []
if mirrors:
    raise SystemExit(
        "Out of sync policy: remove generated mirrors "
        + ", ".join(str(p.relative_to(ROOT)) for p in mirrors[:8])
        + ". Use scripts/link-skills.sh"
    )
print("CHECKED", len(skills), "canonical bucketed skills (no generated mirrors)")
