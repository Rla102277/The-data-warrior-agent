# setup-the-forge

## What it does
Project start: welcome and guiding principles, then menu-driven setup (numbered choices). Records where the code lives, note file, job folders, proof location, and autonomy.

## When to reach for it
First open of a new project after `scripts/install.py`, or when `repo_host` is missing. Prefer `/ask-the-warrior` if you are unsure.

## Common questions
- Does this replace reading the code? No. Inspect evidence first.
- Free-form answers required? No. Reply with a menu number unless you choose “somewhere else” or “I will name…”.
- Do we assume GitHub? No.
- Where do decisions live? In `SCROLL.md` (`repo_host:` in the setup block). Welcome text also lives in `WELCOME.md` after install.

## It's working if
The human saw welcome + principles, answered numbered menus one at a time, and the Scroll has `repo_host` before any CI host is wired.