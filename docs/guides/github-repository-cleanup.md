# GitHub Repository Cleanup Guide

## 🎯 Objective: Clean Public Repository Branch Structure

Following the Private Development + Public Release strategy, the public GitHub repository should only contain the `main` branch to maintain clear separation and professional presentation.

## 🧹 Current Issue

The public GitHub repository may have both `develop` and `main` branches, which violates our LEAN principle of eliminating waste and creating confusion for users.

## ✅ Desired State

**Public Repository (GitHub)**: Only `main` branch
- Contains curated, production-ready releases
- Professional presentation for community
- No development branch confusion

**Private Repository**: `develop` and `master` branches
- `develop`: Active development with CLAUDE.md
- `master`: Release staging (if needed)

## 🔧 Cleanup Steps

### Step 1: Check Current Branch Status

```bash
# Check public repository branches
cd ../task-orchestrator-public
git branch -a

# Check what's on GitHub
gh repo view T72/task-orchestrator --web
```

### Step 2: Remove Develop Branch from GitHub (If Present)

```bash
# Delete develop branch from GitHub remote
git push origin --delete develop

# Or using GitHub CLI
gh api -X DELETE repos/T72/task-orchestrator/git/refs/heads/develop
```

### Step 3: Set Main as Default Branch

In GitHub repository settings:
1. Go to Settings → Branches
2. Set `main` as default branch
3. Remove branch protection from `develop` (if exists)
4. Add branch protection to `main` (recommended):
   - Require pull request reviews
   - Dismiss stale reviews
   - Require status checks

### Step 4: Update Repository Description

```bash
# Update repository description
gh repo edit T72/task-orchestrator --description "Professional task management and orchestration for developers and AI agents"

# Add topics for discoverability
gh repo edit T72/task-orchestrator --add-topic "task-management"
gh repo edit T72/task-orchestrator --add-topic "python"
gh repo edit T72/task-orchestrator --add-topic "cli-tool"
gh repo edit T72/task-orchestrator --add-topic "developer-tools"
gh repo edit T72/task-orchestrator --add-topic "orchestration"
```

### Step 5: Verify Clean State

```bash
# Check final branch structure
gh api repos/T72/task-orchestrator/branches

# Should only show main branch
```

## 📋 LEAN Benefits of Clean Branch Structure

### Waste Elimination
- **User Confusion**: No ambiguity about which branch to use
- **Maintenance Overhead**: Single branch reduces complexity
- **Cognitive Load**: Clear, simple repository structure

### Value Maximization
- **Professional Appearance**: Clean, focused repository
- **User Experience**: Obvious starting point for new users
- **Contribution Clarity**: Clear target for community contributions

### Continuous Improvement
- **Simple Workflow**: Easy to understand and follow
- **Reduced Complexity**: Fewer moving parts to manage
- **Clear Purpose**: Each repository has single, focused purpose

## 🎯 Future Branch Management

### Public Repository Rules
- ✅ **main** branch only
- ❌ **No develop branch**
- ❌ **No feature branches**
- ✅ **Community contributions via forks and PRs to main**

### Private Repository Rules
- ✅ **develop** for active development
- ✅ **master** for release staging (optional)
- ✅ **Feature branches** from develop as needed
- ✅ **Full Git Flow** in private context

### Release Process Alignment
```bash
# Private development
git checkout develop
git add . && git commit -m "feat: new feature"

# Public release
./scripts/create-public-release.sh v2.1.0
cd ../task-orchestrator-public
git push origin main
git push origin v2.1.0
```

## 🚨 Emergency Recovery

If branches get mixed up:

```bash
# 1. Force reset public repository to clean state
cd ../task-orchestrator-public
git checkout main
git reset --hard origin/main

# 2. Re-sync from private repository
cd ../task-orchestrator
./scripts/sync-to-public.sh latest

# 3. Force push clean state
cd ../task-orchestrator-public
git push origin main --force

# 4. Delete any unwanted branches
git push origin --delete develop  # if exists
```

## ✅ Validation Checklist

After cleanup:
- [ ] Public repository has only `main` branch
- [ ] Default branch is set to `main`
- [ ] Repository description is professional
- [ ] Topics are added for discoverability
- [ ] Branch protection rules applied to `main`
- [ ] Private repository retains full development structure
- [ ] Release automation scripts still work
- [ ] Community can contribute via forks → PRs to main

This cleanup ensures the public repository maintains professional standards while the private repository retains full development flexibility.