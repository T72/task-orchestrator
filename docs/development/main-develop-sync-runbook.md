# Main-to-Develop Linear Sync Runbook

## Purpose

Synchronize release/process fixes from `main` into `develop` while respecting branch protections that disallow merge commits in PR branches.

## Preconditions

- Local workspace is clean (or changes safely stashed).
- Remote refs are fresh.
- You have permission to create PRs.

## Procedure

1. Refresh refs:
```bash
git fetch origin --prune
```

2. Inspect main-only candidate commits:
```bash
git log --oneline --no-merges --right-only --cherry-pick origin/develop...origin/main
```

3. Create sync branch from develop:
```bash
git checkout develop
git pull --ff-only origin develop
git checkout -b chore/linear-sync-main-to-develop-<date>
```

4. Cherry-pick selected commits (oldest to newest):
```bash
git cherry-pick <commit-sha-1>
git cherry-pick <commit-sha-2>
```

5. Ensure branch has no merge commits:
```bash
git rev-list --merges origin/develop..HEAD
```
Expected: no output.

6. Push and open PR to develop:
```bash
git push -u origin chore/linear-sync-main-to-develop-<date>
```

Use `.github/pull-request-template/hotfix.md` and document:
- selected commits
- validation checks
- risk/rollback

7. Post-merge verification:
```bash
git fetch origin --prune
git cherry -v origin/develop origin/main
git log --oneline --no-merges --right-only --cherry-pick origin/develop...origin/main
```

## Failure Modes

- **Direct `main` -> `develop` PR blocked**: close it and use this runbook.
- **Cherry-pick conflicts**: resolve conflicts; if commit is already present, skip empty cherry-pick.
- **No commits to pick**: no sync PR needed.

