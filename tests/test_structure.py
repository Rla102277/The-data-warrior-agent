import unittest,tempfile,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def run(*args):
    return subprocess.run([sys.executable,*map(str,args)],capture_output=True,text=True)
class Structure(unittest.TestCase):
    def test_verify(self):
        r=run(ROOT/'scripts/verify.py')
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)
    def test_installer_all_hosts(self):
        for host in ('cursor','claude','codex'):
            with self.subTest(host=host),tempfile.TemporaryDirectory() as d:
                r=run(ROOT/'scripts/install.py',d,'the-scroll','--host',host)
                self.assertEqual(r.returncode,0,r.stdout+r.stderr)
                base={'cursor':'.agents/skills','claude':'.claude/skills','codex':'.agents/skills'}[host]
                self.assertTrue((Path(d)/base/'the-scroll/SKILL.md').exists())
                self.assertTrue((Path(d)/'THE_WAY.md').exists())
                self.assertIn('Role: Rōnin',(Path(d)/'AGENTS.md').read_text())
                self.assertFalse((Path(d)/'skills').exists())
                self.assertFalse((Path(d)/base/'the-interrogation').exists())
    def test_unknown_skill(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertNotEqual(run(ROOT/'scripts/install.py',d,'fake').returncode,0)
    def test_preserve_project_config(self):
        with tempfile.TemporaryDirectory() as d:
            (Path(d)/'AGENTS.md').write_text('Role: Deshi\nCustom instructions\n')
            self.assertEqual(run(ROOT/'scripts/install.py',d,'the-challenge').returncode,0)
            self.assertEqual((Path(d)/'AGENTS.md').read_text(),'Role: Deshi\nCustom instructions\n')
    def test_pipeline_has_concrete_semantics(self):
        t=(ROOT/'skills/forge-the-pipeline/SKILL.md').read_text()
        for term in ('CDC','watermark','SCD','MERGE','deletes','replay','Data Vault'):
            self.assertIn(term,t)
if __name__=='__main__':unittest.main()
