import unittest, tempfile, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def run(*args):
    return subprocess.run([sys.executable, *map(str, args)], capture_output=True, text=True)


class Structure(unittest.TestCase):
    def test_verify(self):
        r = run(ROOT / "scripts/verify.py")
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_sync_check(self):
        r = run(ROOT / "scripts/sync.py", "--check")
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_installer_all_hosts(self):
        for host in ("cursor", "claude", "codex", "all"):
            with self.subTest(host=host), tempfile.TemporaryDirectory() as d:
                r = run(ROOT / "scripts/install.py", d, "the-scroll", "--host", host)
                self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
                self.assertTrue((Path(d) / "THE_WAY.md").exists())
                self.assertTrue((Path(d) / "WELCOME.md").exists())
                self.assertIn("Guiding principles", (Path(d) / "WELCOME.md").read_text())
                agents = (Path(d) / "AGENTS.md").read_text()
                self.assertIn("Role: Rōnin", agents)
                self.assertIn("On project start", agents)
                self.assertFalse((Path(d) / "skills").exists())
                if host in ("cursor", "codex", "all"):
                    self.assertTrue((Path(d) / ".agents/skills/the-scroll/SKILL.md").exists())
                if host in ("claude", "all"):
                    self.assertTrue((Path(d) / ".claude/skills/the-scroll/SKILL.md").exists())
                if host in ("cursor", "all"):
                    self.assertTrue((Path(d) / ".cursor/commands/the-scroll.md").exists())

    def test_preserves_project_instructions(self):
        with tempfile.TemporaryDirectory() as d:
            (Path(d) / "AGENTS.md").write_text("Role: Deshi\nCustom instructions\n")
            r = run(ROOT / "scripts/install.py", d, "the-challenge")
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertEqual((Path(d) / "AGENTS.md").read_text(), "Role: Deshi\nCustom instructions\n")

    def test_unknown_skill_fails(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertNotEqual(run(ROOT / "scripts/install.py", d, "unknown").returncode, 0)

    def test_pipeline_semantics(self):
        s = (ROOT / "skills/forge/the-pipeline/SKILL.md").read_text()
        for term in ("CDC", "watermark", "SCD", "MERGE", "deletes", "replay", "Data Vault"):
            self.assertIn(term, s)

    def test_ground_gate_and_forge(self):
        ground = (ROOT / "skills/ground/know-the-ground/SKILL.md").read_text().lower()
        forge = (ROOT / "skills/forge/the-forge/SKILL.md").read_text().lower()
        self.assertIn("single action", ground)
        self.assertIn("know-the-ground", forge)
        self.assertIn("verdict", forge)

    def test_eval_dry_run_does_not_claim_success(self):
        r = run(ROOT / "scripts/eval.py")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("NOT_RUN", r.stdout)


if __name__ == "__main__":
    unittest.main()
