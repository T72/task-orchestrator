# Task Orchestrator CLI - Agent Deployment Guide

## Overview
This guide explains how to deploy and integrate the Task Orchestrator CLI solution for orchestrating agents and delegated sub-agents in development projects.

## Solution Components

The Task Orchestrator CLI (`task-orchestrator/`) provides:
- **Lightweight task management** for AI agents working in parallel
- **Cross-worktree synchronization** for git-based projects
- **Dependency management** between tasks
- **File reference tracking** for code-related tasks
- **Multi-agent notifications** for coordination

## Quick Deployment

### 1. Basic Installation

```bash
# Navigate to your development project
cd /path/to/your/project

# Copy the task manager solution
cp -r /path/to/task-orchestrator ./task-orchestrator
cd task-orchestrator

# Make executable
chmod +x tm

# Initialize the database
./tm init
```

### 2. Integration Methods

#### Method A: Direct CLI Usage
```bash
# Use directly from task-orchestrator directory
./task-orchestrator/tm add "Implement new feature"
./task-orchestrator/tm list
```

#### Method B: Add to PATH
```bash
# Add to your project's bin directory
mkdir -p ./bin
cp ./task-orchestrator/tm ./bin/
export PATH="$PATH:$(pwd)/bin"

# Now use from anywhere in project
tm add "Fix bug in authentication"
```

#### Method C: Create Alias
```bash
# Add to your shell configuration
alias tm="$(pwd)/task-orchestrator/tm"

# Use the alias
tm list --status pending
```

## Agent Integration Patterns

### Pattern 1: Orchestrating Agent Setup

The orchestrating agent initializes and manages the overall task structure:

```bash
# 1. Initialize task management
tm init

# 2. Create main project structure
EPIC=$(tm add "Complete feature implementation" -p high)

# 3. Break down into sub-tasks with dependencies
API=$(tm add "Design API endpoints" --depends-on $EPIC -p high)
DB=$(tm add "Create database schema" --depends-on $API)
BACKEND=$(tm add "Implement backend logic" --depends-on $DB)
FRONTEND=$(tm add "Build UI components" --depends-on $API)
TESTS=$(tm add "Write integration tests" --depends-on $BACKEND --depends-on $FRONTEND)

# 4. Add file references for precision
tm update $API --file docs/api-spec.yaml
tm update $DB --file schema/migrations/001_initial.sql
tm update $BACKEND --file src/controllers/:src/services/
tm update $FRONTEND --file src/components/:src/views/
```

### Pattern 2: Sub-Agent Task Execution

Sub-agents pick up and execute assigned tasks:

```bash
# 1. Sub-agent checks available tasks
tm list --status pending

# 2. Claim a specific task
TASK_ID=abc12345
tm assign $TASK_ID agent_backend_specialist
tm update $TASK_ID --status in_progress

# 3. Work on the task
# ... implement the feature ...

# 4. Complete with impact review
tm complete $TASK_ID --impact-review

# 5. Check for cascading unblocks
tm watch
```

### Pattern 3: Parallel Agent Coordination

Multiple agents working simultaneously:

```bash
# Agent 1: Frontend specialist
tm list --tag frontend --status pending
tm assign fe_task_123 agent_frontend
tm update fe_task_123 --status in_progress

# Agent 2: Backend specialist  
tm list --tag backend --status pending
tm assign be_task_456 agent_backend
tm update be_task_456 --status in_progress

# Agent 3: Testing specialist (waits for dependencies)
tm list --status blocked
# Monitors for unblocking when frontend/backend complete
tm watch
```

## Configuration

### Environment Variables
```bash
# Optional: Custom database location
export TM_DB_PATH=".task-orchestrator/tasks.db"

# Optional: Lock timeout (seconds)
export TM_LOCK_TIMEOUT=10

# Optional: Agent identification
export TM_AGENT_ID="orchestrator_$(hostname)"
```

### Helper Scripts

Create `agent_helper.sh` for common operations:

```bash
#!/bin/bash
# agent_helper.sh - Helper functions for agents

# Function to claim next available task
claim_next_task() {
    local agent_id=$1
    local tag=$2
    
    # Find next pending task
    local task_id=$(tm list --status pending --tag $tag --format json | jq -r '.[0].id')
    
    if [ ! -z "$task_id" ]; then
        tm assign $task_id $agent_id
        tm update $task_id --status in_progress
        echo $task_id
    fi
}

# Function to complete task with files
complete_with_files() {
    local task_id=$1
    shift
    local files="$@"
    
    for file in $files; do
        tm update $task_id --file $file
    done
    
    tm complete $task_id --impact-review
}
```

## Command Reference

### Essential Commands
```bash
tm init                           # Initialize database
tm add "Task title"              # Create task
tm list                          # List all tasks
tm show <id>                     # Show task details
tm update <id> --status <status> # Update status
tm complete <id>                 # Mark complete
tm assign <id> <agent>           # Assign to agent
tm watch                         # Monitor notifications
```

### Advanced Usage
```bash
# Dependencies
tm add "Deploy" --depends-on task1 --depends-on task2

# File references
tm add "Fix bug" --file src/auth.py:42:45

# Filtering
tm list --status pending --assignee agent1 --tag backend

# Export
tm export --format json > tasks.json
tm export --format markdown > tasks.md
```

## Integration with Development Workflow

### Git Hooks Integration
```bash
# .git/hooks/pre-commit
#!/bin/bash
# Check for incomplete tasks before commit

INCOMPLETE=$(tm list --status in_progress --assignee $(whoami) --format json | jq length)
if [ "$INCOMPLETE" -gt 0 ]; then
    echo "Warning: You have $INCOMPLETE incomplete tasks"
    tm list --status in_progress --assignee $(whoami)
fi
```

### CI/CD Integration
```yaml
# .github/workflows/task-check.yml
name: Task Status Check
on: [push, pull_request]

jobs:
  check-tasks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Check task completion
        run: |
          ./task-orchestrator/tm init
          BLOCKED=$(./task-orchestrator/tm list --status blocked --format json | jq length)
          if [ "$BLOCKED" -gt 0 ]; then
            echo "::warning::There are $BLOCKED blocked tasks"
          fi
```

## Best Practices

### 1. Task Granularity
- Keep tasks small and actionable (2-8 hours of work)
- Use dependencies to maintain logical flow
- Add clear descriptions for complex tasks

### 2. File References
- Always add file references for code changes
- Use line ranges for specific sections
- Update references when files are moved

### 3. Agent Coordination
- Use consistent agent IDs
- Regular `tm watch` checks for notifications
- Complete tasks promptly to unblock others

### 4. Status Management
- Move to `in_progress` when starting work
- Use `blocked` status with clear dependencies
- Complete with `--impact-review` for file changes

## Monitoring & Maintenance

### Database Health
```bash
# Check database size
du -h .task-orchestrator/tasks.db

# Vacuum to optimize
sqlite3 .task-orchestrator/tasks.db "VACUUM;"

# Backup tasks
tm export --format json > backup-$(date +%Y%m%d).json
```

### Lock Management
```bash
# Check for stale locks
ls -la .task-orchestrator/.lock

# Remove if stale (use cautiously)
rm -f .task-orchestrator/.lock
```

## Troubleshooting

### Common Issues

1. **Database Lock Timeout**
```bash
# Increase timeout
export TM_LOCK_TIMEOUT=30
```

2. **Cross-Worktree Access**
```bash
# Ensure database is at repository root
cd $(git rev-parse --show-toplevel)
./task-orchestrator/tm init
```

3. **Agent ID Conflicts**
```bash
# Use unique agent IDs
export TM_AGENT_ID="agent_$(hostname)_$(date +%s)"
```

## Security Considerations

1. **Local Storage**: All data stored locally in repository
2. **No Network Access**: Completely offline operation
3. **File Permissions**: Ensure proper permissions on database
```bash
chmod 660 .task-orchestrator/tasks.db
```

## Example Deployment Scenarios

### Scenario 1: Single Repository, Multiple Features
```bash
# Orchestrator creates feature branches
tm add "Feature A" --tag feature-a
tm add "Feature B" --tag feature-b

# Agents work on different features
tm list --tag feature-a  # Agent 1
tm list --tag feature-b  # Agent 2
```

### Scenario 2: Microservices Architecture
```bash
# Create tasks for each service
tm add "Update auth service" --file services/auth/
tm add "Update user service" --file services/user/
tm add "Update API gateway" --file services/gateway/

# Service-specific agents claim their tasks
tm list --file services/auth/  # Auth team agent
```

### Scenario 3: Bug Fix Workflow
```bash
# Create bug task with reproduction
BUG=$(tm add "Fix login timeout" -p critical --tag bug)
tm update $BUG --file src/auth/session.js:234

# Assign to specialist
tm assign $BUG agent_auth_expert

# Track fix and testing
TEST=$(tm add "Test login timeout fix" --depends-on $BUG)
tm assign $TEST agent_qa
```

## Conclusion

The Task Orchestrator CLI provides a lightweight, effective solution for coordinating multiple AI agents in development projects. Its file-based approach ensures portability, while SQLite provides reliability and concurrent access support. Deploy it in your project to enable efficient multi-agent collaboration with clear task tracking and dependency management.