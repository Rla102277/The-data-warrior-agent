import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class Structure(unittest.TestCase):
 def test_skill_count(self):
  self.assertEqual(len(list((ROOT/'skills').glob('*/SKILL.md'))),15)
 def test_roles(self):
  way=(ROOT/'THE_WAY.md').read_text()
  for role in ('Deshi','Rōnin','Kensei'): self.assertIn(role,way)
 def test_scroll_uses_challenge_method(self):
  self.assertIn('the-interrogation',(ROOT/'skills/the-scroll/SKILL.md').read_text())
 def test_battle_map(self):
  self.assertIn('BATTLE_MAP.md',(ROOT/'skills/the-battle-map/SKILL.md').read_text())
if __name__=='__main__': unittest.main()
