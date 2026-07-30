# wiz

Mirror of public repositories from [github.com/wiz-sec](https://github.com/wiz-sec).

Each repo under `wiz-sec/` is a **git submodule** pinned to the tip of that repo’s default branch.

For agents / other LLMs: see [`CURSOR_CONTEXT.md`](./CURSOR_CONTEXT.md) (living context — keep adding to it).

## Sync (daily)

When refreshing this workspace, pull the latest from the org:

```bash
./scripts/sync-wiz-sec.sh
git add wiz-sec .gitmodules
git commit -m "Sync wiz-sec repos"
```

The sync script:

1. Lists all public repos in the `wiz-sec` org (including archived)
2. Adds any new repos as submodules under `wiz-sec/`
3. Fast-forwards existing submodules to their default-branch tip

Requires [GitHub CLI](https://cli.github.com/) (`gh`) authenticated for API access.
