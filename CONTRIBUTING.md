# Contributing to Task Orchestrator

Thanks for contributing.

## Core Rules

1. One issue per concern.
2. Non-trivial changes require a GitHub issue before implementation.
3. Use release workflow controls; do not bypass them with manual shortcuts.
4. Keep changes incremental and test-backed.

## Development Environment

- Primary dev commands must run in the Windows environment.
- If you are operating from WSL2, invoke development commands through Windows context.
- Python 3.8+ is required.

## Branching

- `develop` is the integration branch.
- `main` is the release branch.
- Normal delivery path: feature/fix -> `develop` -> release PR `develop` -> `main`.
- Use hotfix flow only for urgent production fixes that must start from `main`.

## Testing

Run relevant test suites before PR:

```bash
bash tests/test_tm.sh
bash tests/test_edge_cases.sh
```

If you touch release/governance logic, also ensure workflows pass on PR:

- `governance-baseline`
- `Public Release Boundary`
- `validate` (repo-structure)
- `Enforce main PR template (release or hotfix)` (for `main` PRs)

## Release Workflow

Releases are controlled and must be reproducible.

1. Prepare from `main` only (unless explicit controlled override for dry-runs).
2. Run:
   - `bash scripts/prepare-public-release.sh`
3. The release preparation now chains mandatory managers by default:
   - `scripts/release-and-changelog-management.sh`
   - `scripts/release-public-docs-management.sh`
4. Publish tag explicitly:
   - `bash scripts/publish-release-tag.sh vX.Y.Z`
5. Never use:
   - `git push --tags`

## Release PR Requirements (`develop` -> `main`)

Use the release PR template and ensure these are checked:

- `release-and-changelog-management executed`
- `release-public-docs-management executed`
- artifact references are included in PR body

## Documentation Requirements

For each release, keep these public docs current and version-consistent:

- `VERSION`
- `README.md`
- `CHANGELOG.md`
- `CONTRIBUTING.md`
- `INSTALL.md` / `USAGE.md` (if present)

## Pull Request Guidelines

- Use clear titles: `fix: ...`, `docs: ...`, `hardening: ...`, `release: ...`.
- Keep PR scope focused.
- Link and close relevant issues explicitly in PR body.
- Do not merge if required checks are failing.
