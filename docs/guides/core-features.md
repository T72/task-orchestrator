# Core Features Guide

Master the essential Task Orchestrator capabilities for effective AI agent coordination.

## Task Management

### Creating Tasks with Context
```bash
# Basic task
./tm add "Implement payment processing"

# With priority and description
./tm add "Fix security bug" --priority high -d "SQL injection in login"

# With deadline
./tm add "Prepare demo" --deadline "2025-09-10T15:00:00"

# With time estimate
./tm add "Code review" --estimated-hours 2
```

### Task Dependencies

Build complex workflows with automatic dependency resolution:

```bash
# Linear dependency chain
DESIGN=$(./tm add "Design system" | grep -o '[a-f0-9]\{8\}')
BUILD=$(./tm add "Build system" --depends-on $DESIGN | grep -o '[a-f0-9]\{8\}')
TEST=$(./tm add "Test system" --depends-on $BUILD | grep -o '[a-f0-9]\{8\}')
DEPLOY=$(./tm add "Deploy system" --depends-on $TEST | grep -o '[a-f0-9]\{8\}')

# Multiple dependencies
./tm add "Integration test" --depends-on $BUILD --depends-on $TEST
```

### Status Management
```bash
# Status progression
./tm update task_id --status pending      # Initial state
./tm update task_id --status in_progress  # Working on it
./tm update task_id --status blocked      # Waiting for something
./tm complete task_id                     # Mark as done
```

## Multi-Agent Orchestration

### Agent Assignment
```bash
# Assign to specialists
./tm add "Database optimization" --assignee database_agent
./tm add "API development" --assignee backend_agent
./tm add "UI polish" --assignee frontend_agent
./tm add "Security audit" --assignee security_agent

# View agent workload
./tm list --assignee backend_agent
./tm list --has-assignee  # All assigned tasks
```

### Shared Context

Enable knowledge sharing between agents:

```bash
# Share discoveries
./tm share task_id "API endpoints ready at /api/v2"

# Add private notes
./tm note task_id "Consider caching for performance"

# Announce issues
./tm discover task_id "Found race condition in auth flow"

# View all context
./tm context task_id
```

### Progress Tracking
```bash
# Update progress
./tm progress task_id "Completed 3/5 endpoints"
./tm progress task_id "Running integration tests"

# View progress history
./tm show task_id  # Shows all progress updates
```

## Dependency Resolution

### Automatic Unblocking
When a task completes, dependent tasks automatically unblock:

```bash
# Create chain
BACKEND=$(./tm add "Backend API")
FRONTEND=$(./tm add "Frontend" --depends-on $BACKEND)

# Complete parent
./tm complete $BACKEND
# Frontend automatically becomes ready!

./tm list  # Frontend now shows as 'pending' not 'blocked'
```

### Critical Path Analysis
```bash
# Find bottlenecks
./tm critical-path

# Output shows longest dependency chain
# Helps identify what to prioritize
```

## Success Criteria

Define clear completion conditions:

```bash
# JSON format for criteria
./tm add "User authentication" \
  --criteria '[{
    "criterion": "Users can login",
    "measurable": "true"
  }, {
    "criterion": "Passwords encrypted",
    "measurable": "true"
  }]'

# View criteria
./tm show task_id  # Shows success criteria
```

## Filtering and Search

### List Filtering
```bash
# By status
./tm list --status in_progress
./tm list --status blocked

# By assignment
./tm list --assignee frontend_agent
./tm list --unassigned

# By dependencies
./tm list --has-deps     # Tasks with dependencies
./tm list --no-deps      # Independent tasks
./tm list --is-blocked   # Currently blocked tasks
```

### Complex Queries
```bash
# High priority unassigned tasks
./tm list --priority high --unassigned

# In-progress tasks for specific agent
./tm list --status in_progress --assignee backend_agent

# Ready tasks (not blocked)
./tm list --status pending --no-deps
```

## Real-Time Notifications

### Watch Mode
```bash
# Start monitoring (blocks terminal)
./tm watch

# In another terminal, make changes
./tm complete task_id
# First terminal shows: "Task task_id completed!"
```

### Event Types Monitored
- Task creation
- Status updates
- Task completion
- Dependency resolution
- Progress updates
- Context additions

## Best Practices

### 1. Use Commander's Intent
Always include WHY/WHAT/DONE:
```bash
./tm add "Build search" --context "WHY: Users need to find content
                                   WHAT: Full-text search, filters, sorting
                                   DONE: Users find any content in <2 seconds"
```

### 2. Atomic Tasks
Break large tasks into smaller, atomic units:
```bash
# Instead of: "Build entire system"
# Use:
./tm add "Design database schema"
./tm add "Implement data models"
./tm add "Create API endpoints"
./tm add "Build UI components"
```

### 3. Clear Dependencies
Make dependencies explicit:
```bash
# Good: Clear chain
DESIGN=$(./tm add "Design auth")
IMPLEMENT=$(./tm add "Code auth" --depends-on $DESIGN)
TEST=$(./tm add "Test auth" --depends-on $IMPLEMENT)
```

### 4. Regular Updates
Keep progress visible:
```bash
./tm progress task_id "Starting implementation"
./tm progress task_id "50% complete"
./tm progress task_id "In review"
```

## Next Steps

- **Advanced workflows**: Read [Advanced Usage Guide](advanced-usage.md)
- **Automation**: See [AI Agent Integration](../reference/ai-agent-integration.md)
- **Troubleshooting**: Check [Troubleshooting Guide](troubleshooting.md)

---
*Core features enable 4-5x productivity gains through intelligent orchestration.*