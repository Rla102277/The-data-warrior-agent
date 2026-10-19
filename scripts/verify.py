from pathlib import Path
import subprocess,sys,re,json
ROOT=Path(__file__).resolve().parents[1]
names=sorted(x.parent.name for x in (ROOT/'skills').glob('*/SKILL.md'))
assert len(names)==14, names
assert 'the-interrogation' not in names
for name in names:
    text=(ROOT/'skills'/name/'SKILL.md').read_text()
    assert re.search(r'(?m)^name: '+re.escape(name)+r'$',text)
    desc=re.search(r'(?m)^description: (.+)$',text)
    assert desc and desc.group(1).startswith('Use when'), name
for role in ('Deshi','Rōnin','Kensei'):assert role in (ROOT/'THE_WAY.md').read_text()
assert 'one question' in (ROOT/'skills/the-scroll/SKILL.md').read_text().lower()
assert len(json.loads((ROOT/'evals/scenarios.json').read_text()))>=8
r=subprocess.run([sys.executable,str(ROOT/'scripts/sync.py'),'--check'],capture_output=True,text=True)
assert r.returncode==0,r.stdout+r.stderr
print('PASS: 14 canonical skills, trigger descriptions, named roles, generated adapters')
