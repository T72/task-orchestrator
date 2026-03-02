
# Branching Strategy

## Branch Roles
- `develop` = integration branch (default PR target)
- `main` = release/deploy branch (deployable at all times)

## Normal Flow
- Create `feature/*` branches from `develop`
- PR `feature/*` ? `develop` (CI required)
- Release PR `develop` ? `main` (Release template required)

## Hotfix Flow
- Create `hotfix/*` branch from `main`
- PR `hotfix/*` ? `main` (Hotfix template required)
- After merge: back-merge `main` ? `develop` (automated)

## Merge Methods (Policy)
- `feature/*` ? `develop`: Squash merge
- `develop` ? `main`: Merge commit (release boundary)
- `hotfix/*` ? `main`: Squash merge

## Main-to-Develop Sync Policy

### Governance Decision
- This repository enforces `no merge commits` for PR branches.
- Therefore, direct `main` -> `develop` backmerge PRs are not the default sync mechanism.

### Required Sync Model (Linear)
- Create sync branches from `develop`.
- Cherry-pick required `main` commits onto the sync branch.
- Open PR `sync-branch` -> `develop`.
- Keep sync branches linear (no merge commits).

### Verification Standard
- Ancestry counts (`git rev-list origin/main...origin/develop`) are informational only.
- Required sync evidence is patch/content parity for selected commits:
  - `git log --oneline --no-merges --right-only --cherry-pick origin/develop...origin/main`
  - `git cherry -v origin/develop origin/main`

### Operational Rule
- If a direct `main` -> `develop` PR is opened and blocked by merge policy, close it and create a linear sync PR from `develop`.

## Merge Method Decision Matrix (Canonical)

For this repository, the correct merge method depends on the branch pair:

1. feature/* or fix/* -> develop: Squash and merge (recommended).
2. develop -> main (release PR): Create a merge commit.
3. hotfix/* -> main: Squash and merge.
4. main -> develop sync: do not use direct merge or rebase-merge; use the linear cherry-pick sync PR model.

### Rationale

- This policy is defined in this branching strategy and related governance docs.
- Squash keeps develop clean and supports one-issue-per-commit traceability.
- Merge commit on develop -> main preserves release boundary/history.
- Rebase-merge is not a project standard for these flows and can reduce governance traceability in this model.
