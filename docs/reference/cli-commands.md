# CLI Command Reference

## Status: Implemented
## Last Verified: August 23, 2025
Against version: v2.7.2

## Overview

Task Orchestrator provides a comprehensive command-line interface through the `tm` command. This reference covers all commands, options, and parameters available in v2.7.2.

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

**Examples**:

```bash
# List all tasks
tm list

# List pending tasks
tm list --status pending

# List tasks assigned to backend-agent
tm list --assignee backend-agent

# Combine filters
tm list --status in_progress --has-deps
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

### tm critical-path

Analyze and display the critical path of task dependencies.

```bash
tm critical-path [options]
```

**Options**:
- `--verbose`: Show detailed dependency information
- `--format <type>`: Output format (text, json, graphviz)

**Description**:
Identifies the longest sequence of dependent tasks that determines the minimum project completion time. Helps identify bottlenecks and optimize task scheduling.

**Examples**:

```bash
# Show critical path
tm critical-path
# Output:
# Critical Path Analysis
# ======================
# Path length: 3 tasks
# Estimated duration: 45 hours
# 
# 1. a1b2c3d4: Setup infrastructure (10h)
#    └─> 2. e5f6g7h8: Backend API (20h)
#        └─> 3. i9j0k1l2: Integration tests (15h)

# Verbose output with all paths
tm critical-path --verbose

# Export as Graphviz for visualization
tm critical-path --format graphviz > critical-path.dot
```

---

### tm report

Generate various reports on task metrics and team performance.

```bash
tm report [options]
```

**Options**:
- `--assessment`: Generate 30-day assessment report with recommendations
- `--format <type>`: Output format (text, json, csv)
- `--output <file>`: Save report to file
- `--days <n>`: Number of days to analyze (default: 30)

**Description**:
Creates comprehensive reports analyzing task completion rates, feature adoption, feedback scores, and provides strategic recommendations for improvement.

**Examples**:

```bash
# Generate assessment report
tm report --assessment
# Output:
# ================================================================================
# 30-DAY ASSESSMENT REPORT
# ================================================================================
# 
# EXECUTIVE SUMMARY
# --------------------
# Tasks Created: 47
# Tasks Completed: 38
# Completion Rate: 80.9%
# Feature Adoption Score: 72
# Key Insight: Strong adoption of success criteria feature
# 
# FEATURE ADOPTION ANALYSIS
# ------------------------------
# Success Criteria: 85.1% (40 tasks)
# Deadlines: 63.8% (30 tasks)
# Time Estimation: 70.2% (33 tasks)
# Most Adopted Feature: Success Criteria
# 
# STRATEGIC RECOMMENDATIONS
# ------------------------------
# 1. [HIGH] Increase deadline usage for better planning
#    Action: Add deadline prompts to task creation
# 
# Report saved to: .task-orchestrator/reports/30_day_assessment.txt

# Export as JSON for further analysis
tm report --assessment --format json --output metrics.json

# Custom time period
tm report --days 7 --format csv
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

Share a critical discovery with all agents working on a task.

```bash
tm discover <task-id> <message>
```

**Arguments**:
- `task-id`: The task where the discovery was made
- `message`: The critical finding to share

**Description**:
Broadcasts an important discovery to all agents involved with a task. Creates a high-priority notification that ensures critical information (security issues, blockers, breakthroughs) reaches all team members immediately.

**Example**:

```bash
tm discover a1b2c3d4 "Found SQL injection vulnerability in login endpoint!"
# Output: Discovery shared for task a1b2c3d4
```

**Note**: Discoveries are stored in shared context and trigger notifications to all agents.

---

### tm wizard

Interactive task creation wizard with template support (v2.7.2).

```bash
tm wizard [options]
```

**Options**:
- `--quick`: Quick mode with condensed prompts

**Description**:
Launches an interactive wizard that guides you through task creation. Supports three creation methods:
1. Template-based creation with variable substitution
2. Quick start with basic options
3. Advanced creation with all features

**Examples**:

```bash
# Launch interactive wizard
tm wizard
# Output:
# === Task Creation Wizard ===
# How would you like to create tasks?
# 1. Use a template
# 2. Quick start (basic task)
# 3. Advanced (all options)

# Quick mode for rapid task creation
tm wizard --quick
# Output: Streamlined creation with fewer prompts
```

---

### tm template

Manage and apply task templates (v2.7.2).

```bash
tm template <subcommand> [arguments]
```

**Subcommands**:

#### tm template list
List all available templates.

```bash
tm template list
```

**Output**:
```
Available templates:
- bug-fix: Bug Fix Template
- feature: Feature Development Template
- spike: Research Spike Template
- refactor: Code Refactoring Template
- docs: Documentation Task Template
```

#### tm template show
Display template details.

```bash
tm template show <template-name>
```

**Example**:
```bash
tm template show bug-fix
# Output: Shows template structure with variables and defaults
```

#### tm template apply
Apply a template with variable substitution.

```bash
tm template apply <template-name> [key=value ...]
```

**Example**:
```bash
tm template apply bug-fix severity=critical component=auth issue_id=BUG-123
# Output: Task created with ID: a1b2c3d4
```

---

### tm hooks

Monitor and manage hook performance (v2.7.2).

```bash
tm hooks <subcommand> [arguments]
```

**Subcommands**:

#### tm hooks report
Generate performance report for hooks.

```bash
tm hooks report [hook_name] [days]
```

**Arguments**:
- `hook_name` (optional): Specific hook to report on
- `days` (optional): Number of days to analyze (default: 7)

**Example**:
```bash
tm hooks report
# Output:
# Hook Performance Report (Last 7 days)
# =====================================
# pre_add: 15 executions, avg: 45.2ms, P95: 89ms
# post_complete: 8 executions, avg: 123.5ms, P95: 234ms

tm hooks report pre_add 30
# Output: Detailed report for pre_add hook over 30 days
```

#### tm hooks alerts
View performance alerts.

```bash
tm hooks alerts [severity] [hours]
```

**Arguments**:
- `severity` (optional): Filter by severity (warning, critical)
- `hours` (optional): Hours to look back (default: 24)

**Example**:
```bash
tm hooks alerts critical 48
# Output: Shows critical alerts from last 48 hours
```

#### tm hooks thresholds
Configure performance thresholds.

```bash
tm hooks thresholds [warning_ms] [critical_ms] [timeout_ms]
```

**Arguments**:
- `warning_ms`: Warning threshold in milliseconds (default: 500)
- `critical_ms`: Critical threshold in milliseconds (default: 2000)
- `timeout_ms`: Timeout threshold in milliseconds (default: 10000)

**Example**:
```bash
tm hooks thresholds 300 1500 5000
# Output: Thresholds updated - Warning: 300ms, Critical: 1500ms, Timeout: 5000ms
```

#### tm hooks cleanup
Clean up old performance data.

```bash
tm hooks cleanup [days]
```

**Arguments**:
- `days`: Keep data for this many days (default: 30)

**Example**:
```bash
tm hooks cleanup 7
# Output: Cleaned up 1,234 records older than 7 days
```

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