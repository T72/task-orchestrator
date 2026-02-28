
# Hotfix Pull Request

? This template is for urgent production fixes only.

Use this only when:
- A production issue must be fixed immediately.
- Waiting for the next planned release is not acceptable.

---

## Incident Reference

- Incident / Issue ID:
- Affected environment:
- Severity (Low / Medium / High / Critical):

---

## Root Cause Summary

Brief explanation of what caused the issue.

---

## Scope of This Fix

What exactly is being changed?

- File(s) affected:
- Behavior being corrected:

Explicitly confirm:

- [ ] This PR addresses only the hotfix.
- [ ] No unrelated refactors included.
- [ ] No feature additions included.

---

## TDD & Verification

- [ ] Regression test added (required unless technically impossible).
- [ ] Unit tests pass.
- [ ] Contract tests pass (if applicable).
- [ ] CI is green.

If a regression test could NOT be added, explain why:

---

## Risk Assessment

- [ ] Low risk (isolated change)
- [ ] Medium risk
- [ ] High risk (explain below)

Risk notes:
- Performance impact:
- Compatibility impact:
- Possible side effects:

---

## Rollback Plan (Mandatory)

If deployment fails, we will:

- [ ] Revert this PR
- [ ] Restore previous artifact/image
- [ ] Roll back migrations (if applicable)
- [ ] Other:

---

## Post-Deploy Verification

After deployment, verify:

- [ ] Health endpoints respond correctly
- [ ] Core affected flow tested manually
- [ ] Error logs monitored
- [ ] Metrics stable

---

## Follow-Up Required?

Does this hotfix require:

- [ ] A deeper refactor later
- [ ] An ADR
- [ ] Additional test coverage
- [ ] Documentation update

If yes, link follow-up issue(s):
