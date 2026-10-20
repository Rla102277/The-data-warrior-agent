# setup-the-forge

## What it does
Project start: welcome, guiding principles, collaboration **level** menu, path menus, and a **files to upload/attach** menu. Cursor `sessionStart` / first-prompt hooks plus an always-on rule trigger this when the folder opens and a chat starts.

## When to reach for it
Automatic on new chat after install; or manually when `repo_host` / Role is missing. Prefer `/ask-the-warrior` if you are unsure.

## Common questions
- Does this replace reading the code? No. Inspect evidence first.
- Free-form answers required? No. Reply with a menu number.
- Level vs autonomy? Level = Deshi/Rōnin/Kensei (how we collaborate). Autonomy = how much the assistant builds alone (still never auto-approve production).
- Do we assume GitHub? No.

## It's working if
On a new chat the human sees welcome + level menu without asking for it; Scroll has `repo_host` before CI is wired.