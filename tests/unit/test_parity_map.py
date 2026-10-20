"""The manuscript parity map must point at skills that exist."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

MAPPED = [
    "skills/ground/know-the-ground/SKILL.md",
    "skills/ground/grounding/SKILL.md",
    "skills/ground/survey-the-ground/SKILL.md",
    "skills/ground/simplicity/SKILL.md",
    "skills/ground/tool-choice/SKILL.md",
    "skills/water/adapt/SKILL.md",
    "skills/water/the-pivot/SKILL.md",
    "skills/water/ship-the-eighty/SKILL.md",
    "skills/fire/win-the-room/SKILL.md",
    "skills/wind/name-the-wind/SKILL.md",
    "skills/wind/study-the-wind/SKILL.md",
    "skills/wind/wind-patterns/SKILL.md",
    "skills/void/see-the-void/SKILL.md",
    "skills/void/void-sight/SKILL.md",
    "skills/forge/to-plan/SKILL.md",
    "skills/forge/to-spec/SKILL.md",
    "skills/forge/to-steps/SKILL.md",
    "skills/forge/the-forge/SKILL.md",
    "skills/forge/the-contract/SKILL.md",
    "skills/forge/the-pipeline/SKILL.md",
    "skills/forge/test-the-steel/SKILL.md",
    "skills/forge/review-the-work/SKILL.md",
    "skills/forge/draw-the-blade/SKILL.md",
    "skills/forge/chart-the-path/SKILL.md",
    "skills/forge/lessons-of-battle/SKILL.md",
    "skills/practice/the-scroll/SKILL.md",
    "skills/practice/the-battle-map/SKILL.md",
    "skills/practice/the-challenge/SKILL.md",
    "skills/way/ask-the-warrior/SKILL.md",
    "skills/way/setup-the-forge/SKILL.md",
]


def test_parity_doc_and_mapped_skills_exist() -> None:
    parity = (ROOT / "docs" / "PARITY.md").read_text(encoding="utf-8")
    assert "Behavioral parity across hosts is open" in parity
    assert "synthetic" in parity.lower()
    way = (ROOT / "THE_WAY.md").read_text(encoding="utf-8")
    assert "Council" in way
    assert "not six agents" in way
    for relative in MAPPED:
        assert (ROOT / relative).is_file(), relative
    review = (ROOT / "skills/forge/review-the-work/SKILL.md").read_text(encoding="utf-8")
    assert "not separate agents" in review
