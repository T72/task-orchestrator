# Task Orchestrator Skill Reference

## Intent format

Use this compact intent format for delegated work:

- `WHY`: business or engineering purpose
- `WHAT`: concrete deliverables
- `DONE`: measurable acceptance criteria

Example:

```bash
./tm add "Add audit logging" --assignee backend_agent \
  -d "WHY: compliance and incident traceability, WHAT: structured auth event logs, DONE: all auth actions are logged and queryable"
```

## Coordination patterns

### Sequential pipeline

```bash
DESIGN=$(./tm add "Design storage schema" --assignee architect_agent | grep -o '[a-f0-9]\{8\}')
API=$(./tm add "Implement API endpoints" --assignee backend_agent --depends-on "$DESIGN" | grep -o '[a-f0-9]\{8\}')
UI=$(./tm add "Implement settings UI" --assignee frontend_agent --depends-on "$API" | grep -o '[a-f0-9]\{8\}')
```

### Parallel specialists

```bash
EPIC=$(./tm add "Release authentication feature" --assignee orchestrator_agent | grep -o '[a-f0-9]\{8\}')
./tm add "Backend implementation" --assignee backend_agent --depends-on "$EPIC"
./tm add "Frontend implementation" --assignee frontend_agent --depends-on "$EPIC"
./tm add "Security test plan" --assignee qa_agent --depends-on "$EPIC"
```

## Operational commands

- Current board: `./tm list`
- Current board (machine-readable): `./tm list --format json`
- Single task details: `./tm show <task_id>`
- Live event feed: `./tm watch`

## Troubleshooting quick checks

1. Run `scripts/verify-tm.sh --json`.
2. Confirm `./tm list` returns state.
3. If blocked tasks remain, inspect dependencies with `./tm show <task_id>`.
