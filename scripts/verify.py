from pathlib import Path
import json, sys
root=Path(__file__).resolve().parents[1]
canonical=root/'.agents'/'skills'
names=sorted(p.parent.name for p in canonical.glob('*/SKILL.md'))
assert len(names)==39, f'Expected 39 skills, got {len(names)}'
for name in names:
    content=(canonical/name/'SKILL.md').read_text()
    assert 'name: '+name in content and '## Procedure' in content, name
    assert (root/'.claude'/'skills'/name/'SKILL.md').read_text()==content, name
    assert (root/'.cursor'/'commands'/(name+'.md')).is_file(), name
assert len(json.loads((root/'evals'/'scenarios.json').read_text()))>=8
print(f'PASS: {len(names)} canonical skills and mirrors; trial manifest valid')
