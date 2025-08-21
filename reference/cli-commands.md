# CLI Command Reference

## Overview

Task Orchestrator provides a comprehensive command-line interface through the `tm` command. This reference covers all commands, options, and parameters available in v2.3.

## Basic Syntax

```bash
tm <command> [arguments] [options]
```

## Core Commands

### tm init

Initialize a new task database.

```bash
tm init
```

**Output**: `Task database initialized`

**Creates**: `.task-orchestrator/` directory with database and supporting files

---

### tm add

Create a new task with optional Core Loop features.

```bash
tm add <title> [options]
```

**Arguments**:
- `title` (required): Task description

**Options**:
- `--depends-on <task-id>`: Set task dependencies (can use multiple times)
- `--file <path:line>`: Attach file reference (e.g., `src/auth.py:42`)
- `--priority <level>`: Set priority (low, medium, high, critical)
- `--assignee <agent>`: Assign to specific agent
- `--criteria <json>`: Success criteria array (v2.3)
- `--deadline <iso8601>`: Task deadline (v2.3)
- `--estimated-hours <n>`: Time estimate (v2.3)

**Examples**:

```bash
# Simple task
tm add "Fix login bug"
# Output: Task created with ID: a1b2c3d4

# Task with dependencies
tm add "Deploy to production" --depends-on a1b2c3d4

# Task with Core Loop features
tm add "Implement OAuth" \
  --criteria '[{"criterion":"All tests pass","measurable":"true"},
               {"criterion":"Documentation complete","measurable":"docs_written == true"}]' \
  --deadline "2025-12-31T23:59:59Z" \
  --estimated-hours 20 \
  --priority high \
  --file src/auth.py:100:200
```

---

### tm list

List tasks with optional filters.

```bash
tm list [options]
```

**Options**:
- `--status <status>`: Filter by status (pending, in_progress, completed, blocked)
- `--assignee <agent>`: Show tasks for specific agent
- `--has-deps`: Show only tasks with dependencies
- `--has-files`: Show only tasks with file references

**Examples**:

```bash
# List all tasks
tm list

# List pending tasks
tm list --status pending

# List tasks assigned to backend-agent
tm list --assignee backend-agent

# Combine filters
tm list --status in_progress --has-files
```

**Output Format**:
```
a1b2c3d4 [pending] Fix login bug (Priority: high)
b2c3d4e5 [in_progress] → Implement OAuth (Assigned: backend-agent)
```

---

### tm show

Display detailed information about a task.

```bash
tm show <task-id>
```

**Arguments**:
- `task-id` (required): Task identifier (first 8 characters)

**Example**:

```bash
tm show a1b2c3d4
```

**Output**:
```
Task: a1b2c3d4
Title: Fix login bug
Status: in_progress
Priority: high
Assignee: backend-agent
Created: 2025-08-20T10:30:00
Files: src/auth.py:42
Dependencies: None
Success Criteria: 2 defined
Deadline: 2025-12-31T23:59:59Z
Estimated: 4.0 hours
Progress: 50% - Found root cause
```

---

### tm complete

Mark a task as completed with optional validation and summary.

```bash
tm complete <task-id> [options]
```

**Arguments**:
- `task-id` (required): Task identifier

**Options** (v2.3):
- `--validate`: Run success criteria validation
- `--actual-hours <n>`: Record actual time spent
- `--summary <text>`: Add completion summary
- `--impact-review`: Review impact of completion

**Examples**:

```bash
# Simple completion
tm complete a1b2c3d4

# Completion with validation and metrics
tm complete a1b2c3d4 \
  --validate \
  --actual-hours 3.5 \
  --summary "Fixed race condition in session handling, all tests passing"
```

**Validation Output**:
```
=== Success Criteria Validation Report ===
Overall: 2/2 criteria passed

✓ Criterion 1: All tests pass
  Result: Automatically validated as true

✓ Criterion 2: Documentation complete
  Result: Manual validation required

Task a1b2c3d4 completed
```

---

### tm progress

Add progress update to a task (v2.3).

```bash
tm progress <task-id> <message>
```

**Arguments**:
- `task-id` (required): Task identifier
- `message` (required): Progress update text

**Examples**:

```bash
tm progress a1b2c3d4 "Reproduced bug, investigating cause"
tm progress a1b2c3d4 "50% - Found race condition in auth flow"
tm progress a1b2c3d4 "90% - Fix implemented, running tests"
```

**Output**: `Progress update added to task a1b2c3d4`

---

### tm feedback

Add feedback scores to a completed task (v2.3).

```bash
tm feedback <task-id> [options]
```

**Arguments**:
- `task-id` (required): Task identifier

**Options**:
- `--quality <1-5>`: Quality score
- `--timeliness <1-5>`: Timeliness score
- `--note <text>`: Additional feedback notes

**Example**:

```bash
tm feedback a1b2c3d4 \
  --quality 5 \
  --timeliness 4 \
  --note "Excellent fix, delivered ahead of schedule"
```

**Output**: `Feedback recorded for task a1b2c3d4`

---

### tm metrics

View aggregated metrics and analytics (v2.3).

```bash
tm metrics [options]
```

**Options**:
- `--feedback`: Show feedback metrics

**Example**:

```bash
tm metrics --feedback
```

**Output**:
```
Feedback metrics:
  Average quality: 4.8/5
  Average timeliness: 4.2/5
  Tasks with feedback: 15
  Total tasks: 20
  Feedback coverage: 75.0%
```

---

### tm config

Manage Core Loop configuration (v2.3).

```bash
tm config [options]
```

**Options**:
- `--show`: Display current configuration
- `--enable <feature>`: Enable a feature
- `--disable <feature>`: Disable a feature
- `--minimal-mode`: Enable minimal mode (disables all Core Loop features)
- `--reset`: Reset to default configuration

**Valid Features**:
- `success-criteria`
- `feedback`
- `telemetry`
- `completion-summaries`
- `time-tracking`
- `deadlines`

**Examples**:

```bash
# View configuration
tm config --show

# Enable specific features
tm config --enable feedback
tm config --enable success-criteria

# Disable telemetry
tm config --disable telemetry

# Minimal mode for lightweight operation
tm config --minimal-mode

# Reset to defaults
tm config --reset
```

---

### tm migrate

Manage database schema migrations (v2.3).

```bash
tm migrate [options]
```

**Options**:
- `--status`: Check migration status
- `--apply`: Apply pending migrations
- `--rollback`: Rollback last migration

**Examples**:

```bash
# Check status
tm migrate --status
# Output:
# Applied migrations: 001
# Pending migrations: None
# Up to date: Yes

# Apply migrations
tm migrate --apply
# Output:
# Backup created: ~/.task-orchestrator/backups/tasks_backup_[timestamp].db
# Applying migration 001: Add Core Loop fields...
# ✓ Migration 001 applied

# Rollback if needed
tm migrate --rollback
# Output:
# Restoring from backup...
# Database restored
```

---

### tm assign

Assign a task to an agent.

```bash
tm assign <task-id> <agent-name>
```

**Arguments**:
- `task-id` (required): Task identifier
- `agent-name` (required): Agent identifier

**Example**:

```bash
tm assign a1b2c3d4 backend-agent
```

**Output**: `Task a1b2c3d4 assigned to backend-agent`

---

### tm update

Update task properties.

```bash
tm update <task-id> [options]
```

**Arguments**:
- `task-id` (required): Task identifier

**Options**:
- `--status <status>`: Update status (pending, in_progress, completed)
- `--priority <level>`: Update priority (low, medium, high, critical)

**Example**:

```bash
tm update a1b2c3d4 --status in_progress --priority critical
```

---

### tm delete

Delete a task.

```bash
tm delete <task-id>
```

**Arguments**:
- `task-id` (required): Task identifier

**Example**:

```bash
tm delete a1b2c3d4
```

**Output**: `Task a1b2c3d4 deleted`

---

### tm watch

Monitor for notifications and unblocked tasks.

```bash
tm watch
```

**Output** (when notifications exist):
```
=== 2 New Notification(s) ===
[UNBLOCKED] Task 'Frontend UI' now unblocked (dependency completed)
[DISCOVERY] Critical finding in task a1b2c3d4: Security vulnerability found
```

**Output** (when no notifications):
```
No new notifications
```

---

### tm export

Export tasks in various formats.

```bash
tm export [options]
```

**Options**:
- `--format <format>`: Export format (json, markdown)
- `--output <file>`: Output file path

**Examples**:

```bash
# Export as JSON
tm export --format json --output tasks.json

# Export as Markdown
tm export --format markdown --output tasks.md
```

---

## Collaboration Commands

### tm join

Join a task's collaboration context.

```bash
tm join <task-id>
```

**Example**:

```bash
tm join a1b2c3d4
```

**Output**: `Joined task a1b2c3d4 collaboration`

---

### tm share

Share an update with all agents on a task.

```bash
tm share <task-id> <message>
```

**Example**:

```bash
tm share a1b2c3d4 "Database schema updated, ready for backend work"
```

**Output**: `Shared update for task a1b2c3d4`

---

### tm note

Add a private note to a task.

```bash
tm note <task-id> <message>
```

**Example**:

```bash
tm note a1b2c3d4 "Consider using JWT instead of sessions for stateless auth"
```

**Output**: `Added private note for task a1b2c3d4`

---

### tm discover

Share a critical discovery with all agents.

```bash
tm discover <task-id> <message>
```

**Example**:

```bash
tm discover a1b2c3d4 "Found SQL injection vulnerability in login endpoint!"
```

**Output**: `Discovery shared for task a1b2c3d4`

---

### tm sync

Create a synchronization point for coordination.

```bash
tm sync <task-id> <message>
```

**Example**:

```bash
tm sync a1b2c3d4 "All agents must review before proceeding"
```

**Output**: `Created sync point for task a1b2c3d4`

---

## Environment Variables

Configure Task Orchestrator behavior through environment variables:

- `TM_DB_PATH`: Custom database location (default: `~/.task-orchestrator/tasks.db`)
- `TM_AGENT_ID`: Set agent identifier for collaboration
- `TM_LOCK_TIMEOUT`: Database lock timeout in seconds (default: 10)
- `TM_VERBOSE`: Enable verbose output (0 or 1)
- `TM_TEST_MODE`: Enable test mode for isolated testing

**Example**:

```bash
export TM_AGENT_ID="backend-specialist"
export TM_VERBOSE=1
tm add "Backend task"
```

---

## Return Codes

Task Orchestrator uses standard Unix return codes:

- `0`: Success
- `1`: General error
- `2`: Command syntax error
- `3`: Task not found
- `4`: Database error
- `5`: Validation failure

---

## Common Workflows

### Complete Feature Development

```bash
# 1. Create feature task with criteria
FEATURE=$(tm add "Implement user authentication" \
  --criteria '[{"criterion":"All tests pass","measurable":"true"}]' \
  --estimated-hours 20 | grep -o '[a-f0-9]\{8\}')

# 2. Track progress
tm progress $FEATURE "10% - Designed schema"
tm progress $FEATURE "40% - Backend complete"
tm progress $FEATURE "80% - Frontend integrated"

# 3. Complete with validation
tm complete $FEATURE --validate --actual-hours 18 \
  --summary "Implemented OAuth2 with Google and GitHub providers"

# 4. Add feedback
tm feedback $FEATURE --quality 5 --timeliness 5 \
  --note "Excellent implementation, well documented"
```

### Bug Fix Workflow

```bash
# 1. Create bug task
BUG=$(tm add "Fix memory leak in cache" \
  --priority critical \
  --file src/cache.py:234 | grep -o '[a-f0-9]\{8\}')

# 2. Investigate and update
tm update $BUG --status in_progress
tm progress $BUG "Reproduced issue, memory grows 10MB/hour"
tm progress $BUG "Found leak in event listener cleanup"

# 3. Complete with summary
tm complete $BUG --summary "Fixed event listener cleanup in cache destructor"
```

---

## Tips and Best Practices

1. **Use meaningful task IDs**: The first 8 characters are usually sufficient
2. **Always backup before migrations**: `cp -r ~/.task-orchestrator ~/.task-orchestrator.backup`
3. **Use criteria for important tasks**: Makes success measurable
4. **Add progress updates regularly**: Improves coordination
5. **Collect feedback consistently**: Enables continuous improvement
6. **Configure features to match workflow**: Disable what you don't need

---

## See Also

- [User Guide](../guides/USER_GUIDE.md) - Detailed usage guide
- [Migration Guide](../migration/v2.3-migration-guide.md) - Upgrading to v2.3
- [Configuration Guide](../configuration/config-guide.md) - Configuration details
- [API Reference](API_REFERENCE.md) - Python API documentation