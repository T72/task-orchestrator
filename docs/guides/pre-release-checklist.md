# Pre-Release Checklist

## Purpose
Systematic validation before ANY release to prevent common issues discovered through experience.

## ✅ Pre-Release Validation Checklist

### 1. Version Management
- [ ] Update `/VERSION` file to new version number
- [ ] Run `./scripts/validate-version-consistency.sh --fix`
- [ ] Verify with `./scripts/validate-version-consistency.sh` (must show 0 inconsistencies)
- [ ] Confirm version in README badge matches
- [ ] Confirm version in README footer matches
- [ ] Check CHANGELOG has entry for new version

### 2. Documentation Quality
- [ ] Run comprehensive quality gate:
  ```bash
  ./scripts/comprehensive-quality-gate.sh
  ```
- [ ] Score must be 80+ for public release
- [ ] Remove any internal documentation from public folders
- [ ] Verify all examples are executable
- [ ] Run link validation:
  ```bash
  ./scripts/validate-all-doc-links.sh
  ```

### 3. Repository Separation
- [ ] Verify in private repository (has CLAUDE.md):
  ```bash
  [ -f CLAUDE.md ] && echo "✅ Private repo" || echo "❌ Wrong repo"
  ```
- [ ] No GitHub remote in private repo:
  ```bash
  git remote -v | grep github && echo "❌ Remove GitHub remote!" || echo "✅ Safe"
  ```

### 4. Content Sanitization
- [ ] Check for private content markers:
  ```bash
  grep -r "CLAUDE\|INTERNAL\|PRD\|private" docs/ --include="*.md" | grep -v "CLAUDE.md"
  ```
- [ ] Remove development guides from public sync
- [ ] Replace "Claude" with "AI agents" in public docs
- [ ] Ensure no internal script references

### 5. Sync Safety
- [ ] Backup public repository:
  ```bash
  cp -r ../task-orchestrator-public ../task-orchestrator-public.backup-$(date +%Y%m%d)
  ```
- [ ] Check sync script for dangerous patterns:
  ```bash
  grep '\.env\*' scripts/sync-to-public.sh  # Should not exist
  ```
- [ ] Monitor sync execution for deletions
- [ ] Verify files exist after sync:
  ```bash
  ls ../task-orchestrator-public/*.md
  ```

### 6. Git Pre-Push Validation
- [ ] Do a test push to check for blocks:
  ```bash
  cd ../task-orchestrator-public
  git push --dry-run origin main
  ```
- [ ] If blocked, remove flagged files
- [ ] Ensure success message: "✅ Repository content is safe for public release"

### 7. Final Verification
- [ ] All tests pass:
  ```bash
  ./tests/run_all_tests_safe.sh
  ```
- [ ] README Quick Start works in <2 minutes
- [ ] Version consistency across all files
- [ ] No broken links in documentation
- [ ] Public repo contains only user-focused content

### 8. Release Creation
- [ ] Tag in private repository:
  ```bash
  git tag v2.7.2
  git push origin v2.7.2
  ```
- [ ] Push to public repository:
  ```bash
  cd ../task-orchestrator-public
  git push origin main
  git push origin v2.7.2
  ```

## 🚨 Common Pitfalls to Avoid

1. **Version Mismatch**: Always update VERSION file first
2. **Sync Script Bugs**: Always backup before sync
3. **Private Content Leaks**: Remove, don't sanitize
4. **Broken Links**: Validate before push
5. **Git Hook Blocks**: Expect strict filtering

## 📊 Success Metrics

- Zero git hook rejections
- Version consistency 100%
- Documentation score 80+
- All links valid
- Clean public repository

## 🔄 Post-Release

- [ ] Verify GitHub shows new version
- [ ] Test installation from public repo
- [ ] Document any issues for next release
- [ ] Update this checklist with new learnings

---

*Last updated: 2025-09-03 based on v2.7.2 release experience*