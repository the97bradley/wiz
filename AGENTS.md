# Agent notes

This repository mirrors public [wiz-sec](https://github.com/wiz-sec) GitHub repos as submodules under `wiz-sec/`.

**Living LLM context:** read and append to [`CURSOR_CONTEXT.md`](./CURSOR_CONTEXT.md) for durable repo knowledge across sessions.

## When the user asks to sync / refresh wiz-sec

1. Run `./scripts/sync-wiz-sec.sh` (requires `gh` + network).
2. Stage and commit updated submodule pointers: `git add wiz-sec .gitmodules && git commit -m "Sync wiz-sec repos"`.
3. Push (prefer `main` when the user wants direct main pushes).

Do this on every request that asks to keep wiz-sec repos up to date (including daily re-runs of the same prompt).

After meaningful work, append a short dated note to `CURSOR_CONTEXT.md`.
