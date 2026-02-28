
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
