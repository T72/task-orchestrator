# Collaboration Event Store Performance Baseline (2026-02-28)

## Scope
- Issue: `#2` Concurrency hardening for collaboration context writes.
- Runtime path covered: `tm join/share/note/sync/context/discover` via `tm_production` transactional storage.

## Test Setup
- Command: `bash tests/test_collaboration_event_store.sh`
- Environment: local developer machine, temporary isolated workspace, SQLite event store (`.task-orchestrator/tasks.db`).

## Results
- Concurrent writer correctness test: `30` parallel discovery writes
  - Result: `PASS` (0 lost contributions)
  - Verification source: `collaboration_events` table count by `task_id` and `event_type='discovery'`
- Sequence behavior
  - Result: `PASS` (monotonic event ordering by `seq` primary key)
- Legacy runtime mutation path check
  - Result: `PASS` (`.task-orchestrator/contexts/<task_id>.yaml` not produced by runtime collaboration path)
- High-write baseline
  - Workload: `200` parallel `tm share` writes on one task
  - Observed duration: `3734 ms`

## Notes
- This baseline is intended as a regression reference point, not a strict SLA.
- Future performance regressions should compare against this workload and command path.
