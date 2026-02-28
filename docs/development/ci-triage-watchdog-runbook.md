# CI Triage Watchdog Runbook

## Purpose
Provide a deterministic incident path for failed required checks when primary log retrieval is unavailable or stalled.

## Scope
- Pull requests targeting protected branches (`develop`, `main`)
- Required status checks: `governance`, `boundary-validation`
- Blockers caused by checks, unresolved review conversations, or signature policy

## Watchdog SLA
- `T+0 min`: classify blocker type.
- `T+2 min`: identify failing job/step from check-runs + jobs metadata.
- `T+5 min`: if raw logs are still unavailable, switch to fallback path.
- `T+10 min`: if still blocked without root cause, escalate with explicit decision log.

No indefinite waiting is allowed.

## Step 1 - Classify Merge Blocker
Run:

```bash
gh api repos/T72/task-orchestrator/pulls/<PR_NUMBER> \
  | jq -r '{mergeable,mergeable_state,state,head:.head.sha,base:.base.ref}'
```

Classification matrix:

| Blocker Signal | Meaning | Immediate Action |
|---|---|---|
| required check failed | CI/code issue | Continue to Step 2 |
| required check pending/queued | infrastructure/scheduling | retry monitor until `T+5`, then escalate |
| all comments must be resolved | unresolved review threads | resolve threads or respond |
| commits must have verified signatures | policy gate | sign/rewrite commits or relax branch policy explicitly |
| mergeable=false/conflicting | branch divergence/conflict | rebase/cherry-pick and rerun checks |

## Step 2 - Identify Failing Job and Step
Run:

```bash
gh api repos/T72/task-orchestrator/commits/<HEAD_SHA>/check-runs \
  | jq -r '.check_runs[] | [.id,.name,.status,.conclusion,.html_url] | @tsv'

gh api repos/T72/task-orchestrator/actions/runs/<RUN_ID>/jobs \
  | jq -r '.jobs[] | "JOB\t\(.id)\t\(.name)\t\(.conclusion)\n" + (.steps[] | "STEP\t\(.number)\t\(.name)\t\(.conclusion)")'
```

Record the exact failing step name before attempting fixes.

## Step 3 - Primary Log Retrieval
Attempt log retrieval for up to 5 minutes:

```bash
gh api repos/T72/task-orchestrator/actions/jobs/<JOB_ID>/logs > /tmp/job.log
```

If successful, extract failure signatures:

```bash
rg -n "FAIL:|Traceback|Error|No module named|EOFError|database is locked|exit code" /tmp/job.log
```

## Step 4 - Fallback Path (Mandatory After `T+5`)
If job logs are unavailable:

1. Query check annotations:

```bash
gh api repos/T72/task-orchestrator/check-runs/<CHECK_RUN_ID>/annotations \
  | jq -r '.[] | [.path,.start_line,.annotation_level,.message] | @tsv'
```

2. Download diagnostics artifacts from the failed run:

```bash
gh api repos/T72/task-orchestrator/actions/runs/<RUN_ID>/artifacts \
  | jq -r '.artifacts[] | [.id,.name,.archive_download_url] | @tsv'

gh run download <RUN_ID> --repo T72/task-orchestrator --name <ARTIFACT_NAME> --dir /tmp/diag
```

3. Reproduce the failing step locally in clean worktree:

```bash
bash tests/test_storage_contract.sh
bash tests/test_collaboration_event_store.sh
bash tests/test_error_exit_codes.sh
bash tests/test_public_manifest_pipeline.sh
```

## Step 5 - Decide and Act
- Root cause found:
  - create focused fix commit,
  - rerun checks,
  - close related review thread/comments.
- Root cause not found by `T+10`:
  - publish evidence bundle (commands, outputs, timestamps),
  - escalate as infra/observability incident,
  - do not continue passive waiting.

## Required Evidence Checklist
- PR state snapshot (`mergeable_state`, head SHA, timestamp)
- Check-runs snapshot (status/conclusion for required checks)
- Failing job + step name
- Log retrieval attempts + timestamps
- Artifact retrieval result
- Local reproduction result
- Final decision and next action

## Exit Criteria
- Blocker type explicitly classified.
- Root cause identified or escalation explicitly documented.
- No unbounded monitoring wait remains.
