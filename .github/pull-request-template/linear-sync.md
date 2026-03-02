# Linear Sync Pull Request (develop-based)

Use this template when synchronizing selected `main` commits into `develop` under no-merge-commit branch policy.

---

## Summary

Describe the sync objective and what release/process fixes are being carried over.

---

## Source Commits (from `main`)

List the exact commits cherry-picked onto this branch:

- `<sha>` `<title>`
- `<sha>` `<title>`

---

## Why Linear Sync (instead of direct main -> develop PR)

- Branch policy disallows merge commits in PR branches.
- Direct main -> develop backmerge PRs can be blocked by governance rules.
- Linear sync preserves policy compliance.

---

## Verification Evidence

- [ ] `git log --oneline --no-merges --right-only --cherry-pick origin/develop...origin/main` reviewed
- [ ] Selected commits cherry-picked in oldest -> newest order
- [ ] `git rev-list --merges origin/develop..HEAD` returns no commits
- [ ] CI checks on this PR are green

Paste command outputs or concise evidence:

```text
<evidence>
```

---

## Risk / Impact

- [ ] Low
- [ ] Medium
- [ ] High (explain)

Notes:
- Potential conflict areas:
- Runtime risk:

---

## Rollback Plan

If this sync causes issues:
- [ ] Revert this PR merge on `develop`
- [ ] Open targeted follow-up sync PR with narrowed commit set

---

## Follow-up Required?

- [ ] Governance/docs update
- [ ] Additional sync PR(s)
- [ ] None

Link follow-up issues:

