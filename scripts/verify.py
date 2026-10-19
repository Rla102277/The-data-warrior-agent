from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
names=sorted(p.parent.name for p in (root/'skills').glob('*/SKILL.md'))
assert len(names)==15, f'Expected 15 skills, got {len(names)}'
for name in names:
    body=(root/'skills'/name/'SKILL.md').read_text()
    assert f'name: {name}' in body, name
    for host in ('.agents/skills','.claude/skills'):
        assert (root/host/name/'SKILL.md').read_text()==body, (name,host)
    assert (root/'.cursor/commands'/f'{name}.md').is_file(), name
way=(root/'THE_WAY.md').read_text()
for role in ('Deshi','Rōnin','Kensei'): assert role in way
assert 'A/B/C' not in way
assert 'the-interrogation' in (root/'skills/the-scroll/SKILL.md').read_text()
assert 'BATTLE_MAP.md' in (root/'skills/the-battle-map/SKILL.md').read_text()
assert len(json.loads((root/'evals/scenarios.json').read_text()))>=8
print('PASS: 15 canonical skills, host mirrors, named roles, Scroll/Challenge composition, Battle Map, scenarios')
