
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
