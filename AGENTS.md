# Agent notes

This repository mirrors public [wiz-sec](https://github.com/wiz-sec) GitHub repos as submodules under `wiz-sec/`.

## When the user asks to sync / refresh wiz-sec

1. Run `./scripts/sync-wiz-sec.sh` (requires `gh` + network).
2. Stage and commit updated submodule pointers: `git add wiz-sec .gitmodules && git commit -m "Sync wiz-sec repos"`.
3. Push the branch.

Do this on every request that asks to keep wiz-sec repos up to date (including daily re-runs of the same prompt).
