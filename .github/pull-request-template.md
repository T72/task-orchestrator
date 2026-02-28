# Pull Request

## Linked Issue

Closes #

---

## Type

- [ ] bug
- [ ] refactor
- [ ] feature
- [ ] architecture
- [ ] governance
- [ ] infra
- [ ] performance
- [ ] security
- [ ] test
- [ ] documentation
- [ ] verification

---

## Summary

Concise description of what this PR changes.

---

## TDD Checklist (Required)

- [ ] New behavior has tests (unit or contract).
- [ ] Bug fixes include a regression test.
- [ ] Refactors preserve behavior (tests protect it).
- [ ] No skipped tests introduced.
- [ ] CI is green.

If no tests were added, explain why:

---

## Architectural Integrity Checklist

- [ ] No core → plugin coupling introduced.
- [ ] No unintended public API contract changes.
- [ ] Provider abstraction remains isolated.
- [ ] Middleware ordering preserved (if modified).
- [ ] Breaking change? (If yes, ADR required.)

---

## Issue Hygiene Checklist

- [ ] Linked issue exists and matches this PR’s scope.
- [ ] If linked issue contains `blocked-by`, status labels are correct (`status:blocked` / optional `status:ready`).

---

## Acceptance Criteria Verification

Confirm how each acceptance criterion from the issue is satisfied:

- Criterion 1:
- Criterion 2:
- Criterion 3:

---

## Risk Notes (Optional)

- Performance impact:
- Cost impact:
- Latency impact:
- Migration required:

---

## Additional Notes

Anything reviewers should pay attention to.
