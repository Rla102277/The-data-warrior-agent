"""Generate host-native skill mirrors and Cursor command entrypoints."""
from pathlib import Path
import argparse
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--check',action='store_true')
args=parser.parse_args()
expected={}
for skill in sorted((ROOT/'skills').glob('*/SKILL.md')):
    name=skill.parent.name
    body=skill.read_text(encoding='utf-8')
    for host in ('.agents/skills','.claude/skills'):
        expected[ROOT/host/name/'SKILL.md']=body
    expected[ROOT/'.cursor/commands'/f'{name}.md']=(
        f'# /{name}\n\nFollow the instructions in `.agents/skills/{name}/SKILL.md` '
        f'(or `.claude/skills/{name}/SKILL.md` on Claude Code). '
        'Use the installed THE_WAY.md and project role configuration.\n')
bad=[]
for path,content in expected.items():
    if args.check:
        if not path.is_file() or path.read_text(encoding='utf-8')!=content:bad.append(str(path.relative_to(ROOT)))
    else:
        path.parent.mkdir(parents=True,exist_ok=True)
        path.write_text(content,encoding='utf-8')
if bad:raise SystemExit('Out of sync: '+', '.join(bad))
print(('CHECKED' if args.check else 'SYNCED'),len(expected),'generated host files')
