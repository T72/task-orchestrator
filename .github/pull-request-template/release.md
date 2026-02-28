
# Release Pull Request (develop → main)

## Summary

Describe what this release includes (1–3 sentences).

---

## Release Scope

### Included Milestone(s)
- Milestone: `<Phase> – <Objective>` (link)

### Included Issues
- Closes #___
- Closes #___
- Closes #___

(Keep this list complete. Everything merged in this release should be represented.)

---

## Deployment Readiness Checklist

### Quality Gates
- [ ] CI is green on `develop`
- [ ] CI is green on this PR
- [ ] No skipped tests introduced
- [ ] Unit + contract tests passing
- [ ] (If applicable) Integration tests executed and passing

### TDD Compliance
- [ ] New behavior is covered by tests
- [ ] Bug fixes include regression tests
- [ ] No meaningful test coverage regression

### Architecture & Compatibility
- [ ] No unintended breaking changes
- [ ] Breaking changes documented (if any)
- [ ] ADR added for architectural changes (if applicable)
- [ ] Core/plugin boundaries preserved (if applicable)
- [ ] Provider abstraction unchanged or explicitly documented (if applicable)

### Ops & Runtime
- [ ] Env var changes documented (`.env.example` updated)
- [ ] Migrations documented and safe (if applicable)
- [ ] Health checks verified (if applicable)
- [ ] Observability/logging impact reviewed (if applicable)

---

## Release Notes (User-Facing)

Write short release notes (what changed for consumers).

- Added:
- Changed:
- Fixed:
- Deprecated:

---

## Rollback Plan

How to roll back if deployment fails:

- [ ] Revert merge commit
- [ ] Restore previous container/image version (if applicable)
- [ ] Roll back migrations (if applicable)

---

## Post-Deploy Verification

List the minimal checks to confirm production is healthy:

- [ ] Service responds to health endpoints
- [ ] Key API flows verified
- [ ] Error rate normal
- [ ] Logs show no new critical errors
