"""MVP structural and installability checks."""
from pathlib import Path
import subprocess, sys, re, json
ROOT=Path(__file__).resolve().parents[1]
names=sorted(x.parent.name for x in (ROOT/'skills').glob('*/SKILL.md'))
assert len(names)==14, f'Expected 14 skills, found {len(names)}'
for name in names:
    body=(ROOT/'skills'/name/'SKILL.md').read_text(encoding='utf-8')
    assert re.search(r'(?m)^name: '+re.escape(name)+r'$',body), name
    desc=re.search(r'(?m)^description: (.+)$',body)
    assert desc and desc.group(1).startswith('Use when'),name
for role in ('Deshi','Rōnin','Kensei'):assert role in (ROOT/'THE_WAY.md').read_text()
scroll=(ROOT/'skills/the-scroll/SKILL.md').read_text().lower()
assert 'one consequential question' in scroll and 'superseded' in scroll
assert 'the-interrogation' not in names
assert len(json.loads((ROOT/'evals/scenarios.json').read_text()))>=8
p=subprocess.run([sys.executable,str(ROOT/'scripts/sync.py'),'--check'],capture_output=True,text=True)
assert p.returncode==0,p.stdout+p.stderr
print('PASS: 14 canonical skills, discovery descriptions, roles, Scroll, generated adapters')
