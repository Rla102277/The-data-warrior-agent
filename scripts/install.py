from pathlib import Path
import argparse,shutil
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser(description='Install selected Data Warrior skills')
p.add_argument('target');p.add_argument('skills',nargs='*',help='skill names; default all')
p.add_argument('--overwrite',action='store_true')
a=p.parse_args()
target=Path(a.target).expanduser().resolve()
if not target.is_dir():p.error('Target directory does not exist')
available={x.parent.name for x in (root/'skills').glob('*/SKILL.md')}
chosen=list(a.skills or sorted(available))
for name in chosen:
 if name not in available:p.error('Unknown skill '+name)
if any(x in chosen for x in ('the-challenge','the-scroll')) and 'the-interrogation' not in chosen:chosen.append('the-interrogation')
for name in chosen:
 for host in ('skills','.agents/skills','.claude/skills'):
  src=root/host/name/'SKILL.md';dst=target/host/name/'SKILL.md'
  if dst.exists() and not a.overwrite:print('SKIP',dst);continue
  dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst);print('INSTALLED',dst)
 src=root/'.cursor/commands'/f'{name}.md';dst=target/'.cursor/commands'/f'{name}.md'
 if dst.exists() and not a.overwrite:print('SKIP',dst);continue
 dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst);print('INSTALLED',dst)
print('Review THE_WAY.md and project AGENTS.md manually. No project instructions were overwritten.')
