# Single-Repo Public Release Governance

This project uses a single-repository model:

- Source + distribution repository: `T72/task-orchestrator`

## Source of Truth

- `task-orchestrator` is the development and release source of truth.
- Public distribution is produced from curated release artifacts and GitHub Releases.
- Public-facing subset content is built from an allowlist contract.

## Sync Contract

The file allowlist contract is maintained in:

- `.github/public-sync-allowlist.txt`

Only files listed there are included in the public subset bundle.

## Automation

### Public subset build workflow

- Workflow: `.github/workflows/build-public-subset.yml`
- Trigger: push to `main` + manual dispatch
- Behavior:
  - build allowlisted subset into a staged bundle
  - upload bundle and report as workflow artifacts

## Release Mapping

For each public release, maintain deterministic mapping in one repo:

- Version -> commit SHA -> release artifact(s)

This mapping should be visible in release notes and release artifacts.
