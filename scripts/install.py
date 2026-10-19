"""Install selected skills for one or more agent hosts, plus The Way and role config."""
from pathlib import Path
import argparse, shutil, sys
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('target')
p.add_argument('skills',nargs='*')
p.add_argument('--host',choices=('cursor','claude','codex','all'),default='cursor')
p.add_argument('--overwrite',action='store_true')
a=p.parse_args()
target=Path(a.target).expanduser().resolve()
if not target.is_dir():p.error('Target directory must exist')
available={x.parent.name for x in (ROOT/'skills').glob('*/SKILL.md')}
selected=a.skills or sorted(available)
for name in selected:
    if name not in available:p.error('Unknown skill '+name)
hosts=('cursor','claude','codex') if a.host=='all' else (a.host,)
def copy(src,dst):
    if dst.exists() and not a.overwrite:
        print('SKIP existing',dst)
        return
    dst.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(src,dst)
    print('INSTALLED',dst)
copy(ROOT/'THE_WAY.md',target/'THE_WAY.md')
for host in hosts:
    folder={'cursor':'.agents/skills','claude':'.claude/skills','codex':'.agents/skills'}[host]
    for name in selected:
        copy(ROOT/'skills'/name/'SKILL.md',target/folder/name/'SKILL.md')
        if host=='cursor':
            # Generate thin command without requiring mirrored source in this repository.
            command=target/'.cursor/commands'/f'{name}.md'
            if not command.exists() or a.overwrite:
                command.parent.mkdir(parents=True,exist_ok=True)
                command.write_text(f'# /{name}\n\nFollow `.agents/skills/{name}/SKILL.md` and THE_WAY.md.\n')
                print('INSTALLED',command)
config=target/'AGENTS.md'
if not config.exists():
    config.write_text('# Agent project instructions\n\nRole: Rōnin\n\nRead THE_WAY.md. Roles affect collaboration, never permissions.\n')
    print('INSTALLED',config)
elif 'Role:' not in config.read_text():
    print('NOTE: Add Role: Rōnin to AGENTS.md to select a role')
if 'claude' in hosts:
    config=target/'CLAUDE.md'
    if not config.exists():
        config.write_text('# Claude project instructions\n\nRole: Rōnin\n\nRead THE_WAY.md.\n')
        print('INSTALLED',config)
print('Ready:',', '.join(hosts),'with',len(selected),'skills')
