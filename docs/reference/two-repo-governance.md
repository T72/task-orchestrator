# Two-Repo Governance (Internal + Public)

This project uses a two-repository model:

- Internal source repository: `T72/task-orchestrator`
- Public distribution repository: `T72/task-orchestrator-public`

## Source of Truth

- `task-orchestrator` is the only development source of truth.
- `task-orchestrator-public` is a curated release mirror for external consumption.
- Public content is promoted from internal `main` only, never edited manually first in public.

## Sync Contract

The file allowlist contract is maintained in:

- `.github/public-sync-allowlist.txt`

Only files listed there are allowed to flow into `task-orchestrator-public`.

## Automation

### Promotion workflow

- Workflow: `.github/workflows/promote-to-public-repo.yml`
- Trigger: release published or manual dispatch
- Behavior:
  - sync allowlisted files into public repo branch
  - open/update PR in public repo

### Drift detection workflow

- Workflow: `.github/workflows/check-public-repo-drift.yml`
- Trigger: weekly schedule + manual dispatch
- Behavior:
  - compare allowlisted files between repos
  - fail on drift
  - upload drift report artifact

## Required Secret

These workflows require a token with access to `task-orchestrator-public`:

- `PUBLIC_REPO_TOKEN`

Recommended scope: minimum repo permissions needed to read, push sync branch, and create PR in the public repo.

## Release Mapping

For each public release, maintain deterministic mapping:

- Version -> internal commit SHA -> public promotion PR/commit

This mapping should be visible in release notes or promotion PR metadata.
