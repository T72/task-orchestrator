# Advanced Usage Guide

Unlock the full power of Task Orchestrator for complex orchestration scenarios.

## Template System

### Creating Templates
```bash
# Interactive template builder
./tm template create

# From existing task
./tm template create --from-task task_id --name "api-endpoint"
```

### Using Templates
```bash
# List available templates
./tm template list

# Apply template
./tm template apply api-endpoint \
  --var endpoint_name="users" \
  --var methods="GET,POST,PUT,DELETE"

# Show template details
./tm template show api-endpoint
```

## Bulk Operations

### Batch Task Creation
```bash
# Create multiple related tasks
for endpoint in users posts comments; do
  ./tm add "Implement $endpoint API" --assignee backend_agent
done

# Import from file
while read task; do
  ./tm add "$task"
done < tasks.txt
```

### Mass Updates
```bash
# Update all blocked tasks
for id in $(./tm list --status blocked --format id); do
  ./tm update $id --status pending
done

# Reassign all tasks from one agent to another
for id in $(./tm list --assignee agent1 --format id); do
  ./tm update $id --assignee agent2
done
```

## Custom Workflows

### Pipeline Pattern
```bash
#!/bin/bash
# pipeline.sh - Automated pipeline

# Define stages
stages=("design" "implement" "test" "review" "deploy")
assignees=("architect" "developer" "qa_agent" "reviewer" "devops")

# Create pipeline
prev_id=""
for i in ${!stages[@]}; do
  stage=${stages[$i]}
  assignee=${assignees[$i]}
  
  if [ -z "$prev_id" ]; then
    prev_id=$(./tm add "Stage: $stage" --assignee $assignee | grep -o '[a-f0-9]\{8\}')
  else
    prev_id=$(./tm add "Stage: $stage" --assignee $assignee --depends-on $prev_id | grep -o '[a-f0-9]\{8\}')
  fi
done
```

### Parallel Execution Pattern
```bash
# Create parallel tasks with common dependency
PREP=$(./tm add "Prepare environment")

# Parallel tasks
./tm add "Run unit tests" --depends-on $PREP --assignee test_agent
./tm add "Run integration tests" --depends-on $PREP --assignee test_agent
./tm add "Run performance tests" --depends-on $PREP --assignee perf_agent
./tm add "Security scan" --depends-on $PREP --assignee security_agent

# Convergence point
DEPLOY=$(./tm add "Deploy if all pass")
# Add all test tasks as dependencies for deploy
```

## Performance Optimization

### Database Optimization
```bash
# Clean completed tasks older than 30 days
./tm cleanup --older-than 30d --status completed

# Vacuum database
./tm maintenance --vacuum

# Analyze query performance
./tm performance --analyze
```

### Efficient Queries
```bash
# Use specific filters to reduce load
./tm list --status in_progress --assignee backend_agent --limit 10

# Use ID prefixes for faster lookup
./tm show a1b2  # Matches a1b2c3d4-...

# Batch operations
./tm complete task1 task2 task3  # Complete multiple at once
```

## Integration Patterns

### CI/CD Integration
```yaml
# .github/workflows/task-orchestrator.yml
name: Task Orchestrator CI/CD

on:
  push:
    branches: [main]

jobs:
  update-tasks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Update task status
        run: |
          ./tm update ${{ github.event.issue.number }} --status in_progress
      - name: Run tests
        run: |
          ./tm progress ${{ github.event.issue.number }} "Running CI/CD"
          make test
      - name: Complete task
        if: success()
        run: |
          ./tm complete ${{ github.event.issue.number }}
```

### Git Hooks Integration
```bash
# .git/hooks/post-commit
#!/bin/bash
# Auto-update task on commit

commit_msg=$(git log -1 --pretty=%B)
task_id=$(echo $commit_msg | grep -o '#[a-f0-9]\{8\}' | tr -d '#')

if [ ! -z "$task_id" ]; then
  ./tm progress $task_id "Committed: $commit_msg"
fi
```

## Monitoring & Analytics

### Performance Metrics
```bash
# Task completion rate
./tm metrics --completion-rate --period 7d

# Agent performance
./tm metrics --by-assignee --period 30d

# Bottleneck analysis
./tm metrics --bottlenecks

# Cycle time
./tm metrics --cycle-time
```

### Custom Reports
```bash
# Export to JSON for analysis
./tm list --format json > tasks.json

# Generate weekly report
./tm report --weekly --format markdown > weekly-report.md

# Team velocity
./tm report --velocity --team backend_team
```

## Advanced Configuration

### Environment Variables
```bash
# Set default agent ID
export TM_AGENT_ID="orchestrator"

# Custom database location
export TM_DB_PATH="/shared/tasks/.task-orchestrator"

# Enable debug mode
export TM_DEBUG=1

# Set default priority
export TM_DEFAULT_PRIORITY="medium"
```

### Configuration File
```bash
# Create config
./tm config --init

# Set orchestration enforcement
./tm config --enforce-orchestration true

# Set enforcement level
./tm config --enforcement-level strict

# Show current config
./tm config --show
```

## Scripting & Automation

### Python Integration
```python
#!/usr/bin/env python3
import subprocess
import json

def get_tasks(status=None):
    cmd = ["./tm", "list", "--format", "json"]
    if status:
        cmd.extend(["--status", status])
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    return json.loads(result.stdout)

def auto_assign():
    """Auto-assign unassigned tasks based on keywords"""
    tasks = get_tasks(status="pending")
    
    for task in tasks:
        if not task.get('assignee'):
            title = task['title'].lower()
            
            if 'database' in title or 'sql' in title:
                assignee = 'database_agent'
            elif 'api' in title or 'backend' in title:
                assignee = 'backend_agent'
            elif 'ui' in title or 'frontend' in title:
                assignee = 'frontend_agent'
            else:
                assignee = 'general_agent'
            
            subprocess.run(["./tm", "update", task['id'], 
                          "--assignee", assignee])
            print(f"Assigned {task['id']} to {assignee}")

if __name__ == "__main__":
    auto_assign()
```

### Shell Functions
```bash
# Add to ~/.bashrc

# Quick task add
tma() {
    ./tm add "$1" ${@:2}
}

# Quick complete
tmc() {
    ./tm complete "$1"
}

# Quick list
tml() {
    ./tm list "$@"
}

# Find task by title
tmf() {
    ./tm list | grep -i "$1"
}
```

## Troubleshooting Advanced Issues

### Database Lock Issues
```bash
# Find and kill locked processes
lsof .task-orchestrator/tasks.db
kill -9 <PID>

# Force unlock
./tm maintenance --force-unlock
```

### Performance Issues
```bash
# Profile slow queries
./tm performance --profile

# Rebuild indices
./tm maintenance --rebuild-indices

# Check database integrity
./tm maintenance --check-integrity
```

### Recovery Procedures
```bash
# Backup before recovery
cp -r .task-orchestrator .task-orchestrator.backup

# Export all data
./tm export --all > tasks-backup.json

# Restore from backup
./tm import < tasks-backup.json

# Verify restoration
./tm list --all
```

## Next Steps

- **Getting started**: Review [Getting Started Guide](getting-started.md)
- **Core features**: See [Core Features Guide](core-features.md)
- **AI Integration**: Read [AI Agent Integration](../reference/ai-agent-integration.md)
- **API Reference**: Check [API Reference](../reference/api-reference.md)

---
*Advanced usage enables complex orchestration patterns with minimal overhead.*