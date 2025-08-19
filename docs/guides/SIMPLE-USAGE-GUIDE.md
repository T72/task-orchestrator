# Task Orchestrator - Simple Usage Guide

## Quick Start (30 seconds)

```bash
# 1. Copy the task manager to your project
cp tm_production.py /your/project/tm
chmod +x /your/project/tm

# 2. Create your first task
./tm add "Build authentication system"
# Output: Created task: abc12345

# 3. Join and collaborate
./tm join abc12345
./tm share abc12345 "Started working on OAuth2"
./tm complete abc12345
```

That's it! Files are automatically managed and cleaned up.

## Core Commands (Only what you need)

### Creating Tasks
```bash
tm add "Task title"                           # Simple task
tm add "Task title" -d "Description"          # With description
tm add "Deploy" --depends-on abc123 def456    # With dependencies
```

### Working on Tasks
```bash
tm list                        # See all tasks
tm join TASK_ID               # Join a task's collaboration
tm update TASK_ID --status in_progress       # Update status
tm complete TASK_ID           # Complete (auto-archives)
```

### Collaboration
```bash
tm share TASK_ID "Progress update"     # Share with team
tm discover TASK_ID "Found bug in API" # Share discovery
tm sync TASK_ID "Ready for testing"    # Create sync point
tm note TASK_ID "Private thoughts"     # Private notes
```

### View Information
```bash
tm list --status pending       # Filter tasks
tm context TASK_ID            # View task context
```

## Real-World Examples

### Example 1: Orchestrator Creates Project
```bash
# Orchestrator sets up project structure
MAIN=$(tm add "Build user management API")
AUTH=$(tm add "Authentication" --depends-on $MAIN)
DB=$(tm add "Database schema" --depends-on $MAIN)
API=$(tm add "REST endpoints" --depends-on $AUTH $DB)

# Share requirements
tm join $MAIN
tm share $MAIN "Requirements: JWT auth, PostgreSQL, REST API"
```

### Example 2: Sub-Agent Joins and Works
```bash
# Backend developer joins
export TM_AGENT_ID="backend_dev"
tm list --status pending          # See available tasks
tm join abc123                    # Join authentication task
tm update abc123 --status in_progress

# Work and share progress
tm note abc123 "Research: Using bcrypt for passwords"
tm share abc123 "Database schema complete"
tm discover abc123 "JWT library has security issue - using alternative"

# Complete when done
tm complete abc123
```

### Example 3: Multi-Agent Coordination
```bash
# Frontend dev
export TM_AGENT_ID="frontend"
tm join task123
tm share task123 "UI components ready"
tm sync task123 "Frontend ready for API integration"

# Backend dev sees sync point
export TM_AGENT_ID="backend"
tm context task123    # See frontend is ready
tm share task123 "API endpoints live at /api/v1"

# QA tester
export TM_AGENT_ID="qa"
tm join task123
tm discover task123 "CORS issue on localhost:3000"
```

## What Happens Automatically

### File Management (You don't need to worry about this)
- ✅ Context files created when you `join` a task
- ✅ Notes saved when you use `note` command
- ✅ Archives created when you `complete` a task
- ✅ Old archives deleted after 30 days
- ✅ File size limits enforced (10MB max)

### Dependency Management
- ✅ Blocked tasks become pending when dependencies complete
- ✅ No circular dependencies allowed
- ✅ Status updates cascade automatically

## Environment Variables (Optional)

```bash
# Set your agent ID (otherwise auto-generated)
export TM_AGENT_ID="your_agent_name"

# Then all commands use this identity
tm share task123 "Update from your_agent_name"
```

## Installation Options

### Option 1: Single File (Recommended)
```bash
# Just copy the script
cp tm_production.py ~/bin/tm
chmod +x ~/bin/tm
```

### Option 2: Alias
```bash
# Add to ~/.bashrc or ~/.zshrc
alias tm="python3 /path/to/tm_production.py"
```

### Option 3: Project Local
```bash
# Keep in project
cp tm_production.py ./scripts/tm
./scripts/tm add "New feature"
```

## FAQ

**Q: Where are files stored?**
A: In `.task-orchestrator/` at your git repository root. Everything is automatic.

**Q: How do I clean up old files?**
A: You don't! Files are auto-archived on completion and deleted after 30 days.

**Q: Can multiple agents work on the same task?**
A: Yes! Just have each agent `join` the task. They'll share context automatically.

**Q: What if I need to recover an old task?**
A: Archives are kept for 30 days in `.task-orchestrator/archives/`

**Q: How do I customize retention period?**
A: You don't need to. 30 days is optimal for most projects.

## Best Practices

1. **Keep task titles clear and concise**
   ```bash
   tm add "Fix login bug"           # Good
   tm add "Bug"                     # Too vague
   ```

2. **Join tasks before working**
   ```bash
   tm join task123                  # Always join first
   tm share task123 "Starting work" # Then share
   ```

3. **Complete tasks to trigger cleanup**
   ```bash
   tm complete task123              # Archives and cleans automatically
   ```

4. **Use discoveries for important findings**
   ```bash
   tm discover task123 "Performance issue in query"
   ```

## Troubleshooting

### "Command not found"
```bash
# Make sure script is executable
chmod +x tm
# Or use python directly
python3 tm add "Task"
```

### "Not in a git repository"
```bash
# Initialize git (task manager uses git root)
git init
```

### "Task not found"
```bash
# List all tasks to see valid IDs
tm list
```

## That's All!

The task manager handles everything else internally:
- ✅ Automatic file cleanup
- ✅ Archive compression
- ✅ Size monitoring
- ✅ Concurrent access safety
- ✅ Dependency tracking

Just focus on your tasks - the system handles the rest!