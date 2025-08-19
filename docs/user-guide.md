# Task Orchestrator User Guide

A comprehensive guide to using Task Orchestrator for efficient task management and team coordination.

## Table of Contents

- [Quick Start (5 Minutes)](#quick-start-5-minutes)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Advanced Features](#advanced-features)
- [Claude Code Integration](#claude-code-integration)
- [Best Practices](#best-practices)
- [Common Workflows](#common-workflows)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)

## Quick Start (5 Minutes)

Get up and running with Task Orchestrator in under 5 minutes:

```bash
# 1. Clone and setup (30 seconds)
git clone https://github.com/T72/task-orchestrator.git
cd task-orchestrator
chmod +x tm
./tm init

# 2. Create your first task (30 seconds)
./tm add "Set up development environment" --priority high

# 3. Create a dependency chain (1 minute)
SETUP_ID=$(./tm add "Install dependencies" | grep -o '[a-f0-9]\{8\}')
TEST_ID=$(./tm add "Run tests" --depends-on $SETUP_ID | grep -o '[a-f0-9]\{8\}')
DEPLOY_ID=$(./tm add "Deploy to staging" --depends-on $TEST_ID | grep -o '[a-f0-9]\{8\}')

# 4. View your tasks (30 seconds)
./tm list

# 5. Start working and update status (2 minutes)
./tm update $SETUP_ID --status in_progress
./tm complete $SETUP_ID
./tm list  # Notice the test task is now unblocked
```

You now have a working task orchestration system! Continue reading for advanced features.

## Installation

### System Requirements

- **Python**: 3.8 or higher
- **OS**: Linux, macOS, or Windows (with WSL)
- **Disk Space**: 10MB minimum
- **Memory**: 50MB runtime memory

### Installation Methods

#### Method 1: Git Clone (Recommended)

```bash
# Clone the repository
git clone https://github.com/T72/task-orchestrator.git
cd task-orchestrator

# Make executable (Linux/macOS)
chmod +x tm

# Windows users
python tm init
```

#### Method 2: Direct Download

```bash
# Download latest release
curl -L https://github.com/T72/task-orchestrator/releases/latest/download/tm -o tm
chmod +x tm
```

#### Method 3: Pip Install (Future)

```bash
# Coming soon
pip install task-orchestrator
```

### Verification

```bash
# Test installation
./tm init
./tm add "Test task"
./tm list

# Should show your test task
```

## Basic Usage

### Essential Commands

#### Initialize Database

```bash
# Must run once per repository
./tm init
```

#### Task Creation

```bash
# Simple task
./tm add "Fix login bug"

# Task with description and priority
./tm add "Refactor authentication" \
  --description "Move auth logic to separate module for better maintainability" \
  --priority high

# Task with file reference
./tm add "Fix type error in auth.py" --file src/auth.py:42

# Task with line range
./tm add "Refactor user validation" --file src/models/user.py:100:150

# Task with tags
./tm add "Update documentation" --tag docs --tag maintenance
```

#### Task Management

```bash
# List all tasks
./tm list

# Filter by status
./tm list --status pending
./tm list --status in_progress

# Filter by assignee
./tm list --assignee alice

# Show task details
./tm show abc12345

# Update task status
./tm update abc12345 --status in_progress

# Assign task
./tm assign abc12345 alice

# Complete task
./tm complete abc12345
```

#### Dependencies

```bash
# Create dependent task
./tm add "Deploy feature" --depends-on abc12345

# Multiple dependencies
./tm add "Integration tests" --depends-on abc12345 def67890

# View dependency graph
./tm list --has-deps
```

### Understanding Task Statuses

| Status | Symbol | Description | When to Use |
|--------|--------|-------------|-------------|
| `pending` | ○ | Ready to work on | Default for new tasks |
| `in_progress` | ◐ | Currently being worked on | When you start work |
| `completed` | ● | Task is finished | When work is done |
| `blocked` | ⊘ | Waiting for dependencies | Automatic when dependencies exist |
| `cancelled` | ✗ | Task was abandoned | When task is no longer needed |

### Priority Levels

| Priority | Symbol | Use Case | Example |
|----------|--------|----------|---------|
| `low` | | Nice to have improvements | Code cleanup, minor optimizations |
| `medium` | | Standard work (default) | Feature development, routine maintenance |
| `high` | ! | Important tasks | Bug fixes, security updates |
| `critical` | !! | Urgent blockers | Production outages, security vulnerabilities |

## Advanced Features

### File References and Context

#### Linking Files to Tasks

```bash
# Single file
./tm add "Fix memory leak" --file src/cache.py:234

# Multiple files
./tm add "Refactor auth system" \
  --file src/auth.py:1:50 \
  --file src/models/user.py:25 \
  --file tests/test_auth.py

# With context description
./tm add "Optimize database queries" \
  --file src/db/queries.py:100:200 \
  --description "Focus on the user lookup functions"
```

#### Viewing File References

```bash
# Show task with file references
./tm show abc12345

# Output includes:
# File References:
#   - src/auth.py:42-60
#   - src/models/user.py:25
```

### Dependency Management

#### Creating Complex Workflows

```bash
# Epic breakdown example
EPIC=$(./tm add "User Authentication Epic" --priority critical)

# Core dependencies
AUTH_API=$(./tm add "Implement auth API" --depends-on $EPIC)
AUTH_UI=$(./tm add "Build login UI" --depends-on $AUTH_API)
AUTH_TESTS=$(./tm add "Write auth tests" --depends-on $AUTH_UI)

# Parallel work that can start independently
DOCS=$(./tm add "Document auth API" --depends-on $AUTH_API)
SECURITY=$(./tm add "Security audit" --depends-on $AUTH_API)

# Final integration
INTEGRATION=$(./tm add "Integration testing" --depends-on $AUTH_TESTS $DOCS $SECURITY)
```

#### Dependency Visualization

```bash
# See all tasks with dependencies
./tm list --has-deps

# Export for visualization
./tm export --format markdown > project_status.md
```

### Notifications and Alerts

#### Checking Notifications

```bash
# Check for new notifications
./tm watch

# Example output:
# You have 2 notification(s):
# 
# [unblocked] Task abc12345: Implement user login
#   Task def67890 completed, unblocking this task
# 
# [impacted] Task ghi90123: Update user tests  
#   Your task may be impacted by changes to src/auth.py
```

#### Notification Types

- **unblocked**: Dependencies completed, task is ready
- **impacted**: Related files changed, review may be needed
- **conflict**: Multiple agents working on same files
- **completed**: Tasks in your watch list finished

### Export and Reporting

#### JSON Export

```bash
# Export all tasks
./tm export --format json > tasks.json

# Use with external tools
cat tasks.json | jq '.[] | select(.status == "pending") | .title'
```

#### Markdown Reports

```bash
# Generate status report
./tm export --format markdown > weekly_report.md

# Example output includes:
# - Summary statistics
# - Task breakdowns by status
# - Dependency information
# - Recent activity
```

## Claude Code Integration

Task Orchestrator integrates seamlessly with Claude Code for AI-assisted development workflows.

### Basic Integration

```bash
# Set environment variable for Claude Code
export TM_CLAUDE_INTEGRATION=true

# Claude Code can now:
# - Automatically create tasks from comments
# - Reference specific files and lines
# - Update task status during work
# - Generate task reports
```

### Claude Code Commands

```bash
# In Claude Code, you can use:
# @tm add "Fix authentication bug" --file auth.py:42
# @tm update abc12345 --status in_progress
# @tm complete abc12345 --impact-review
```

### Automated Workflows

#### File Change Detection

```bash
# When Claude Code modifies files, Task Orchestrator can:
# 1. Check for related tasks
# 2. Send notifications to relevant team members  
# 3. Update task statuses automatically
# 4. Create follow-up tasks if needed
```

#### Code Review Integration

```bash
# Before completing tasks, Claude Code can:
# 1. Check if changes impact other tasks
# 2. Notify affected team members
# 3. Suggest related tasks that may need updates
# 4. Generate handoff documentation
```

## Best Practices

### Task Creation Guidelines

#### 1. Write Clear, Actionable Titles

```bash
# Good
./tm add "Fix memory leak in user cache"
./tm add "Add rate limiting to API endpoints"
./tm add "Update user model validation"

# Avoid
./tm add "Fix stuff"
./tm add "Work on the thing"
./tm add "Update code"
```

#### 2. Use Meaningful Descriptions

```bash
# Good
./tm add "Optimize database queries" \
  --description "Profile and optimize slow queries in user dashboard. Focus on N+1 query issues and add appropriate indexes."

# Avoid empty or vague descriptions
./tm add "Database work"
```

#### 3. Set Appropriate Priorities

```bash
# Critical: Production issues, security vulnerabilities
./tm add "Fix authentication bypass" --priority critical

# High: Important features, significant bugs
./tm add "Implement password reset" --priority high

# Medium: Regular development work (default)
./tm add "Add user preferences page"

# Low: Nice-to-have improvements
./tm add "Improve error message styling" --priority low
```

### Dependency Best Practices

#### 1. Keep Dependencies Minimal

```bash
# Good: Clear, necessary dependency
SETUP=$(./tm add "Setup test database")
./tm add "Run integration tests" --depends-on $SETUP

# Avoid: Unnecessary coupling
./tm add "Update documentation" --depends-on $UNRELATED_TASK
```

#### 2. Use Logical Grouping

```bash
# Feature development flow
DESIGN=$(./tm add "Design user profile page")
BACKEND=$(./tm add "Implement profile API" --depends-on $DESIGN)
FRONTEND=$(./tm add "Build profile UI" --depends-on $BACKEND)
TESTING=$(./tm add "Test profile feature" --depends-on $FRONTEND)
```

### File Reference Best Practices

#### 1. Be Specific with Line Numbers

```bash
# Good: Specific location
./tm add "Fix validation logic" --file src/models/user.py:45:60

# Less useful: Entire file
./tm add "Fix validation logic" --file src/models/user.py
```

#### 2. Group Related Files

```bash
# Related files for a feature
./tm add "Implement user search" \
  --file src/api/users.py:100 \
  --file src/models/user.py:25 \
  --file frontend/components/UserSearch.jsx
```

### Team Coordination

#### 1. Use Consistent Agent IDs

```bash
# Set consistent agent ID
export TM_AGENT_ID="alice_dev"

# Or use automatic detection (default)
# Agent ID based on username and process
```

#### 2. Regular Status Updates

```bash
# Update status when starting work
./tm update abc12345 --status in_progress

# Add progress notes
./tm update abc12345 --impact "Fixed validation, working on error handling"

# Complete with impact review
./tm complete abc12345 --impact-review
```

#### 3. Check Notifications Regularly

```bash
# Add to your shell profile
alias tmwatch='./tm watch'

# Check at start of day
tmwatch

# Check after completing tasks
./tm complete abc12345 && tmwatch
```

## Common Workflows

### Workflow 1: Feature Development

```bash
# 1. Plan the feature
FEATURE=$(./tm add "User profile management feature" --priority high)

# 2. Break down into tasks
API=$(./tm add "Design profile API endpoints" --depends-on $FEATURE)
MODEL=$(./tm add "Create user profile model" --depends-on $API)
VIEWS=$(./tm add "Implement profile views" --depends-on $MODEL)
UI=$(./tm add "Build profile UI components" --depends-on $VIEWS)
TESTS=$(./tm add "Write profile tests" --depends-on $UI)

# 3. Assign and track
./tm assign $API alice
./tm assign $UI bob
./tm assign $TESTS charlie

# 4. Work and update
./tm update $API --status in_progress
# ... do work ...
./tm complete $API --impact-review
```

### Workflow 2: Bug Fix

```bash
# 1. Create bug task with context
BUG=$(./tm add "Fix login timeout issue" \
  --priority critical \
  --file src/auth/session.py:89 \
  --description "Users getting timeout after 5 minutes instead of 30")

# 2. Investigate and add findings
./tm update $BUG --status in_progress
./tm update $BUG --impact "Found issue in session timeout calculation"

# 3. Create follow-up tasks if needed
TEST=$(./tm add "Add session timeout tests" --depends-on $BUG)
DOCS=$(./tm add "Update session documentation" --depends-on $BUG)

# 4. Complete with review
./tm complete $BUG --impact-review
```

### Workflow 3: Sprint Planning

```bash
# 1. Create sprint epic
SPRINT=$(./tm add "Sprint 23: User Experience Improvements" --priority high)

# 2. Add sprint tasks
./tm add "Improve loading states" --depends-on $SPRINT --tag sprint23 --tag ux
./tm add "Add error boundaries" --depends-on $SPRINT --tag sprint23 --tag ux
./tm add "Optimize image loading" --depends-on $SPRINT --tag sprint23 --tag performance

# 3. Assign team members
./tm list --tag sprint23 | while read task; do
  # Assign based on expertise
done

# 4. Track progress
./tm list --tag sprint23 --status pending
./tm list --tag sprint23 --status in_progress
```

### Workflow 4: Release Preparation

```bash
# 1. Create release task
RELEASE=$(./tm add "Prepare v2.1.0 release" --priority critical)

# 2. Create release checklist
./tm add "Update changelog" --depends-on $RELEASE
./tm add "Version bump" --depends-on $RELEASE
./tm add "Run full test suite" --depends-on $RELEASE
./tm add "Update documentation" --depends-on $RELEASE
./tm add "Create release notes" --depends-on $RELEASE

# 3. Track completion
./tm list --has-deps | grep $RELEASE
```

## Configuration

### Environment Variables

```bash
# Agent identification
export TM_AGENT_ID="your_unique_id"

# Database location override
export TM_DB_PATH="/custom/path/tasks.db"

# Lock timeout (seconds)
export TM_LOCK_TIMEOUT=30

# Enable verbose logging
export TM_VERBOSE=1

# Claude Code integration
export TM_CLAUDE_INTEGRATION=true
```

### Configuration File

Task Orchestrator can use a `.task-orchestrator/config.json` file:

```json
{
  "agent_id": "alice_dev",
  "default_priority": "medium", 
  "auto_assign": true,
  "notification_settings": {
    "email": false,
    "console": true,
    "file": ".task-orchestrator/notifications.log"
  },
  "export_settings": {
    "include_completed": true,
    "max_age_days": 90
  }
}
```

### Advanced Configuration

#### Custom Database Schema

```bash
# For advanced users: extend the schema
sqlite3 .task-orchestrator/tasks.db << 'EOF'
ALTER TABLE tasks ADD COLUMN estimated_hours INTEGER;
ALTER TABLE tasks ADD COLUMN actual_hours INTEGER;
EOF
```

#### Integration Hooks

```bash
# Post-completion hook
echo '#!/bin/bash
echo "Task $1 completed at $(date)" >> completion.log
' > .task-orchestrator/hooks/post-complete
chmod +x .task-orchestrator/hooks/post-complete
```

## Troubleshooting

### Common Issues

#### 1. Database Lock Errors

**Problem**: "Could not acquire database lock"

**Solutions**:
```bash
# Check for stale lock file
ls -la .task-orchestrator/.lock

# Remove if stale (use caution)
rm .task-orchestrator/.lock

# Increase timeout
export TM_LOCK_TIMEOUT=60
```

#### 2. Permission Errors

**Problem**: Permission denied when accessing database

**Solutions**:
```bash
# Check permissions
ls -la .task-orchestrator/

# Fix permissions
chmod 755 .task-orchestrator
chmod 644 .task-orchestrator/tasks.db
```

#### 3. Circular Dependencies

**Problem**: "Adding these dependencies would create a circular dependency"

**Solutions**:
```bash
# Review dependency chain
./tm show task_id

# Remove circular dependency
./tm update task_id --depends-on  # Remove dependencies

# Restructure workflow
# Break circular tasks into smaller, linear tasks
```

#### 4. Missing Dependencies

**Problem**: "Dependencies not found"

**Solutions**:
```bash
# Check if dependency task exists
./tm show dependency_task_id

# Create missing dependency first
./tm add "Missing dependency task"

# Then add your task with correct dependency
```

### Performance Issues

#### Large Task Lists

```bash
# Use limits for large databases
./tm list --limit 50

# Filter by status
./tm list --status pending --limit 20

# Export and use external tools for analysis
./tm export --format json | jq '.[] | select(.status == "pending")'
```

#### Slow Database Operations

```bash
# Check database size
ls -lh .task-orchestrator/tasks.db

# Consider archiving old tasks
./tm export --format json > archive_$(date +%Y%m%d).json
# Then manually clean old completed tasks
```

### Getting Help

#### Diagnostic Information

```bash
# Check system info
./tm --version
python3 --version
sqlite3 --version

# Check database integrity
sqlite3 .task-orchestrator/tasks.db "PRAGMA integrity_check;"

# Export for debugging
./tm export --format json > debug_export.json
```

#### Log Files

```bash
# Enable verbose logging
export TM_VERBOSE=1
./tm list

# Check system logs (Linux)
journalctl -u task-orchestrator

# Check application logs
tail -f .task-orchestrator/debug.log
```

#### Community Support

- **GitHub Issues**: Report bugs and request features
- **Discussions**: Ask questions and share workflows
- **Documentation**: Check the full documentation suite
- **Examples**: Browse the `docs/examples/` directory

For more advanced topics, see:
- [Developer Guide](developer-guide.md) - Contributing and extending
- [API Reference](reference/api-reference.md) - Complete API documentation
- [Troubleshooting Guide](troubleshooting.md) - Detailed problem resolution