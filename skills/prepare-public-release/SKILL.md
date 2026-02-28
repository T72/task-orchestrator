---
name: prepare-public-release
description: Prepare a production-ready public software release package including version validation, artifact sanitization, changelog generation, licensing checks, distribution packaging, and release documentation. Use before publishing software to users, customers, open-source repositories, marketplaces, or external stakeholders.
---

# /prepare-public-release

Prepare a public-facing software release suitable for external distribution.

## Inputs

- Optional explicit version argument, for example `v1.2.0`
- Repository root path (current working directory)

## Output

Create a release folder under `public-releases/<version>/` with:

- `release-package.*`
- `README.md`
- `CHANGELOG.md`
- `RELEASE_NOTES.md`
- `RELEASE_MANIFEST.md`
- `LICENSE`
- `THIRD_PARTY_LICENSES.md`

## Workflow

0. Enforce release source branch
- Default release branch to `main`.
- Abort if current git branch is not the release branch.
- Require `HEAD` to equal `origin/main` by default (configurable via `RELEASE_REF`).
- Allow explicit override only for exceptional dry-runs (`ALLOW_NON_RELEASE_BRANCH=1`).
- Record branch and commit in release manifest for traceability.

1. Detect project context
- Detect language ecosystem, build system, package manager, and repository structure.
- Resolve version with successor-release semantics:
  1. If explicit version is provided, require semver (`vX.Y.Z` or `X.Y.Z`) and normalize to `vX.Y.Z`.
  2. Discover metadata version from `VERSION`, `package.json`, `pyproject.toml`/`setup.py`, or `Cargo.toml`.
  3. Discover highest released version from semver git tags and `CHANGELOG.md` headings.
  4. Choose candidate:
     - If metadata version exists and is greater than highest released version, use metadata version.
     - Otherwise compute next version from highest released version (or metadata, or `v0.0.0` if none):
       - major bump if commit history indicates breaking change (`BREAKING CHANGE` or conventional-commit `!:` markers)
       - minor bump if history includes `feat:`
       - patch bump otherwise
       - initial release default: `v0.1.0`
  5. Enforce monotonicity and uniqueness:
     - candidate must be greater than latest semver tag
     - candidate must not already exist as a tag
     - if conflict, increment patch until valid

2. Enforce public safety sanitization
- Exclude or remove non-public material from release artifacts:
  - `.env`, credentials, API keys, tokens, private certificates
  - internal docs, staging configs, local paths
  - debug artifacts and experimental scripts
- Abort preparation if sensitive data is detected and cannot be safely excluded.

3. Validate license and compliance
- Ensure `LICENSE` exists.
- Check dependency license compatibility and attribution requirements.
- If missing, create baseline files:
  - `LICENSE`
  - `NOTICE`
  - `THIRD_PARTY_LICENSES.md`

4. Generate changelog
- Create or update `CHANGELOG.md` with:
  - Added
  - Fixed
  - Breaking changes
  - Migration notes
  - Upgrade risks
- Source from commits, merged PR titles, release notes, and ADR summaries when available.
- If `release-and-changelog-management` is available, allow optional delegation for changelog and release notes generation.
- If delegation is unavailable or fails in auto mode, fall back to built-in generation.
- Use delegate-only mode only when external tooling is required and validated.

5. Prepare public documentation
- Ensure `README.md`, `INSTALL.md`, and `USAGE.md` exist and are externally usable.
- Ensure README includes: overview, install, quickstart, configuration, supported environments, version, and license reference.

6. Build and package artifacts
- Prefer native artifact format by detected project type:
  - Node: npm package/build
  - Python: wheel/sdist
  - Go: binary
  - Java: jar
  - Docker: image definition
  - Generic: source archive
- Emit archive formats:
  - Unix: `.tar.gz`
  - Windows: `.zip`

7. Capture reproducibility snapshot
- Generate `RELEASE_MANIFEST.md` with:
  - commit SHA
  - dependency lock references
  - build command
  - runtime requirements
  - platform assumptions

8. Generate public release notes
- Create `RELEASE_NOTES.md` for external audiences with:
  - summary
  - new features
  - bug fixes
  - breaking changes
  - upgrade guide
  - known limitations
  - support information
- Record whether changelog/release-notes were delegated or generated in built-in mode in `RELEASE_MANIFEST.md`.

9. Run final validation checklist
- Verify package extraction and install path.
- Verify doc links and version consistency.
- Verify no internal references remain.
- Publish release tag with explicit single-tag command:
  - `bash scripts/publish-release-tag.sh <version>`
- Never use bulk tag publication (`git push --tags`) in release flow.
- Confirm checklist:
  - [ ] Version tagged
  - [ ] License present
  - [ ] Changelog updated
  - [ ] Documentation complete
  - [ ] Secrets removed
  - [ ] Build reproducible
  - [ ] Install verified

## Error handling

- Missing version: auto-generate.
- Missing license: create template files.
- Secrets detected: abort until sanitized.
- Build unavailable: package source distribution.
- Missing docs: generate baseline docs and continue.

## Success criteria

- External user can install in less than 10 minutes.
- Build is reproducible from version and commit.
- Artifacts are public-safe.
- Upgrade path is documented.
- Legal redistribution requirements are met.
