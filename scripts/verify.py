"""Validate skill packaging and host adapters without brittle prose checks."""
from pathlib import Path
import json,re,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
skills=sorted((ROOT/'skills').glob('*/SKILL.md'))
assert len(skills)==14,f'Expected 14 canonical skills; found {len(skills)}'
for path in skills:
 body=path.read_text(encoding='utf-8')
 match=re.match(r'---\nname: ([a-z0-9-]+)\ndescription: ([^\n]+)\n---',body)
 assert match,f'Invalid skill frontmatter: {path}'
 name,desc=match.groups()
 assert name==path.parent.name,(name,path)
 assert desc.startswith(('Use when ','Use after ','Use to ')),(name,desc)
 assert len(desc)>=45,(name,'description too vague')
 assert len(body.strip())>len(desc)+70,(name,'empty skill')
way=(ROOT/'THE_WAY.md').read_text(encoding='utf-8')
for role in ('Deshi','Rōnin','Kensei'):assert role in way
scroll=(ROOT/'skills/the-scroll/SKILL.md').read_text().lower()
assert 'question per turn' in scroll and 'superseded' in scroll
scenarios=json.loads((ROOT/'evals/scenarios.json').read_text())
assert len(scenarios)>=8
check=subprocess.run([sys.executable,str(ROOT/'scripts/sync.py'),'--check'],capture_output=True,text=True)
assert check.returncode==0,check.stdout+check.stderr
print('PASS: canonical skill packaging, discoverability, role settings and generated adapters')
