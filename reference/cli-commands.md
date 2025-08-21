# CLI Command Reference

## Status: Implemented
- **Implemented**: All commands documented here are fully functional in v2.3.0
- **Implementation**: Available through `tm` wrapper script

## Last Verified: 2025-08-21
Against version: 2.3.0

## Overview

Task Orchestrator provides a comprehensive command-line interface through the `tm` command. This reference covers all commands, options, and parameters available in v2.3.0.

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
- `--depends-on <task-id>`: Set task dependencies (comma-separated for multiple)
- `--priority <level>`: Set priority (low, medium, high, critical)
- `--assignee <agent>`: Assign to specific agent
- `--criteria <json>`: Success criteria array (v2.3)
- `--deadline <iso8601>`: Task deadline (v2.3)
- `--estimated-hours <n>`: Time estimate (v2.3)
- `--description <text>`: Detailed description

**Examples**:

```bash
# Simple task
tm add "Fix login bug"
# Output: Task created with ID: a1b2c3d4

# Task with dependencies (use actual task IDs)
tm add "Deploy to production" --depends-on a1b2c3d4,b2c3d4e5

# Task with Core Loop features
tm add "Implement OAuth" \
  --criteria '[{"criterion":"All tests pass","measurable":"true"}]' \
  --deadline "2025-12-31T23:59:59Z" \
  --estimated-hours 20 \
  --priority high
```

**Note**: The command returns ONLY the task ID (8 characters), not the full message shown above.

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
- `--limit <n>`: Limit number of results
- `--format <type>`: Output format (table, json, markdown)

**Examples**:

```bash
# List all tasks
tm list

# List pending tasks
tm list --status pending

# List tasks assigned to backend-agent
tm list --assignee backend-agent

# Export as JSON
tm list --format json
```

**Output Format** (default):
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
```yaml
Task: a1b2c3d4
Title: Fix login bug
Status: in_progress
Priority: high
Assignee: backend-agent
Created: 2025-08-20T10:30:00
Dependencies: None
Success Criteria: 2 defined
Deadline: 2025-12-31T23:59:59Z
Estimated: 4.0 hours
Progress Updates: 3
```

---

### tm update

Update task properties.

```bash
tm update <task-id> [options]
```

**Arguments**:
- `task-id` (required): Task identifier

**Options**:
- `--status <status>`: Update status (pending, in_progress, completed, blocked)
- `--priority <level>`: Update priority (low, medium, high, critical)
- `--assignee <agent>`: Update assignment

**Example**:

```bash
tm update a1b2c3d4 --status in_progress --priority critical
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

**Examples**:

```bash
# Simple completion
tm complete a1b2c3d4

# Completion with validation and metrics
tm complete a1b2c3d4 \
  --validate \
  --actual-hours 3.5 \
  --summary "Fixed race condition in session handling"
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

## Core Loop v2.3 Commands

### tm progress

Add progress update to a task.

```bash
tm progress <task-id> <message>
```

**Arguments**:
- `task-id` (required): Task identifier
- `message` (required): Progress update text

**Examples**:

```bash
tm progress a1b2c3d4 "Reproduced bug, investigating cause"
tm progress a1b2c3d4 "50% - Found race condition"
tm progress a1b2c3d4 "90% - Fix implemented, running tests"
```

**Output**: Progress update added

---

### tm feedback

Add feedback scores to a completed task.

```bash
tm feedback <task-id> [options]
```

**Arguments**:
- `task-id` (required): Task identifier

**Options**:
- `--quality <1-5>`: Quality score
- `--timeliness <1-5>`: Timeliness score
- `--notes <text>`: Additional feedback notes

**Example**:

```bash
tm feedback a1b2c3d4 \
  --quality 5 \
  --timeliness 4 \
  --notes "Excellent fix, ahead of schedule"
```

**Output**: `Feedback recorded`

---

### tm metrics

View aggregated metrics and analytics.

```bash
tm metrics [options]
```

**Options**:
- `--period <time>`: Time period (week, month, quarter)
- `--agent <name>`: Filter by agent

**Example**:

```bash
tm metrics
```

**Output**:
```
=== Task Metrics ===
Total Tasks: 42
Completed: 35
In Progress: 5
Success Rate: 95%
Avg Completion Time: 6.5 hours
```

---

### tm config

Manage Core Loop configuration.

```bash
tm config [options]
```

**Options**:
- `--show`: Display current configuration
- `--enable <feature>`: Enable a feature
- `--disable <feature>`: Disable a feature
- `--minimal-mode`: Enable minimal mode
- `--reset`: Reset to default configuration

**Valid Features**:
- `success_criteria`
- `feedback`
- `telemetry`
- `completion_summaries`
- `time_tracking`
- `deadlines`

**Examples**:

```bash
# View configuration
tm config --show

# Enable features
tm config --enable feedback

# Minimal mode
tm config --minimal-mode

# Reset
tm config --reset
```

---

### tm migrate

Manage database schema migrations.

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

# Apply migrations
tm migrate --apply
```

---

## Collaboration Commands

### tm join

Join a task's collaboration context.

```bash
tm join <task-id> [--role <description>]
```

**Example**:

```bash
tm join a1b2c3d4 --role "Frontend implementation"
```

**Output**: `Joined task a1b2c3d4`

---

### tm share

Share an update with all agents on a task.

```bash
tm share <task-id> <message> [--type <type>]
```

**Types**: update, discovery, decision

**Example**:

```bash
tm share a1b2c3d4 "Database schema updated" --type update
```

**Output**: Update shared

---

### tm note

Add a private note to a task.

```bash
tm note <task-id> <message>
```

**Example**:

```bash
tm note a1b2c3d4 "Consider JWT for stateless auth"
```

**Output**: Note added

---

### tm context

View all shared context for a task.

```bash
tm context <task-id>
```

**Example**:

```bash
tm context a1b2c3d4
```

**Output**: YAML-formatted shared context

---

### tm sync

Create a synchronization checkpoint.

```bash
tm sync <task-id> <checkpoint-name>
```

**Example**:

```bash
tm sync a1b2c3d4 "backend_complete"
```

---

### tm watch

Monitor for notifications and unblocked tasks.

```bash
tm watch [--limit <n>]
```

**Output** (when notifications exist):
```
=== 2 New Notification(s) ===
[UNBLOCKED] Task 'Frontend UI' now unblocked
[SHARED] Update on task a1b2c3d4
```

---

### tm export

Export tasks in various formats.

```bash
tm export [options]
```

**Options**:
- `--format <format>`: Export format (json, markdown, csv)
- `--status <status>`: Filter by status
- `--output <file>`: Output file path

**Examples**:

```bash
# Export as JSON
tm export --format json --output tasks.json

# Export completed tasks as Markdown
tm export --format markdown --status completed
```

---

## Environment Variables

Configure Task Orchestrator behavior:

- `TM_DB_PATH`: Custom database location (default: `~/.task-orchestrator/tasks.db`)
- `TM_AGENT_ID`: Set agent identifier for collaboration
- `TM_DEBUG`: Enable debug output (1/0)
- `TM_TEST_MODE`: Enable test mode for isolated testing

**Example**:

```bash
export TM_AGENT_ID="backend-specialist"
tm add "Backend task"
```

---

## Exit Codes

Task Orchestrator uses standard Unix exit codes:

- `0`: Success
- `1`: General error
- `2`: Validation error
- `3`: Database error
- `4`: Dependency error
- `5`: Permission error

---

## Common Workflows

### Complete Feature Development

```bash
# 1. Create feature task
FEATURE=$(tm add "Implement authentication" \
  --criteria '[{"criterion":"All tests pass"}]' \
  --estimated-hours 20)
echo "Created task: $FEATURE"

# 2. Track progress
tm progress $FEATURE "10% - Designed schema"
tm progress $FEATURE "40% - Backend complete"
tm progress $FEATURE "80% - Frontend integrated"

# 3. Complete with validation
tm complete $FEATURE --validate --actual-hours 18 \
  --summary "OAuth2 with Google and GitHub"

# 4. Add feedback
tm feedback $FEATURE --quality 5 --timeliness 5
```

### Multi-Agent Collaboration

```bash
# Agent 1: Database specialist
tm join $TASK --role "Database design"
tm share $TASK "Schema ready" --type update

# Agent 2: Backend developer
tm join $TASK --role "API implementation"
tm note $TASK "Consider caching strategy"
tm share $TASK "Endpoints complete" --type update

# Agent 3: Frontend developer
tm join $TASK --role "UI implementation"
tm context $TASK  # View all shared updates
```

---

## Tips and Best Practices

1. **Task IDs**: First 8 characters are usually sufficient
2. **Backup before migrations**: `cp -r ~/.task-orchestrator ~/.task-orchestrator.backup`
3. **Use progress updates**: Improves multi-agent coordination
4. **Private vs Shared**: Use `note` for thinking, `share` for coordination
5. **Watch regularly**: Monitor for unblocked tasks and updates

---

## See Also

- [API Reference](./api-reference.md) - Python API documentation
- [Database Schema](./database-schema.md) - Storage architecture
- [Claude Integration Guide](./claude-integration-guide.md) - AI agent workflows
- [User Guide](../guides/USER_GUIDE.md) - Detailed usage guide

---

*Last Updated: 2025-08-21*
*Version: 2.3.0*