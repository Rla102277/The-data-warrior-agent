from pathlib import Path
import argparse, shutil
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('target')
p.add_argument('--overwrite',action='store_true')
a=p.parse_args()
target=Path(a.target).expanduser().resolve()
if not target.is_dir(): p.error('Target must be an existing directory')
for folder in ('.agents/skills','.claude/skills','.cursor/commands'):
    src=root/folder
    for f in src.rglob('*'):
        if not f.is_file(): continue
        dst=target/f.relative_to(root)
        if dst.exists() and not a.overwrite:
            print('SKIP existing:',dst); continue
        dst.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(f,dst); print('INSTALLED',dst)
print('Review and merge THE_WAY.md and AGENTS.md manually; never overwrite target project authority.')
