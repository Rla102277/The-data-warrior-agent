import unittest
import tempfile
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class Structure(unittest.TestCase):
    def test_structure_verifier(self):
        result = subprocess.run([sys.executable, str(ROOT / "scripts/verify.py")],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_roles_have_distinct_behaviors(self):
        way = (ROOT / "THE_WAY.md").read_text()
        for role in ("Deshi", "Rōnin", "Kensei"):
            self.assertIn(role, way)
        campaign = (ROOT / "skills/the-campaign/SKILL.md").read_text()
        for role in ("Deshi", "Rōnin", "Kensei"):
            self.assertIn(role, campaign)

    def test_scroll_and_challenge_share_interrogation(self):
        for name in ("the-scroll", "the-challenge"):
            self.assertIn("the-interrogation", (ROOT / "skills" / name / "SKILL.md").read_text())
        self.assertIn("superseded", (ROOT / "skills/the-scroll/SKILL.md").read_text())

    def test_battle_map_requires_evidence(self):
        body = (ROOT / "skills/the-battle-map/SKILL.md").read_text()
        self.assertIn("verified", body)
        self.assertIn("unknown", body)

    def test_install_selected_skill_and_dependency(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run([sys.executable, str(ROOT / "scripts/install.py"), tmp,
                                     "the-scroll"], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertTrue((Path(tmp) / "skills/the-scroll/SKILL.md").is_file())
            self.assertTrue((Path(tmp) / "skills/the-interrogation/SKILL.md").is_file())
            self.assertTrue((Path(tmp) / ".cursor/commands/the-scroll.md").is_file())
            self.assertFalse((Path(tmp) / "skills/the-campaign/SKILL.md").exists())

    def test_install_unknown_skill_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run([sys.executable, str(ROOT / "scripts/install.py"), tmp,
                                     "not-a-skill"], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)

if __name__ == "__main__":
    unittest.main()
