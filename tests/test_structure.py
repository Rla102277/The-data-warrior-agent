import unittest
from pathlib import Path
class Structure(unittest.TestCase):
 def test_skill_count(self):
  root=Path(__file__).resolve().parents[1]
  self.assertEqual(len(list((root/'.agents/skills').glob('*/SKILL.md'))),39)
 def test_constitution(self):
  root=Path(__file__).resolve().parents[1]
  self.assertIn('Never self-escalate',(root/'THE_WAY.md').read_text())
 def test_cursor_rules(self):
  root=Path(__file__).resolve().parents[1]
  self.assertTrue((root/'.cursor/rules/the-way.mdc').is_file())
if __name__=='__main__':unittest.main()
