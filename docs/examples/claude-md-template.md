# Task Orchestrator Instructions for CLAUDE.md

Add this section to your project's CLAUDE.md file to enable Claude Code to use Task Orchestrator effectively:

---

## Task Orchestrator Integration

**IMPORTANT**: This project uses Task Orchestrator (`./tm`) for managing tasks and coordinating work between multiple AI agents.

### Quick Reference

Task Orchestrator is installed at: `./tm`
Database location: `.task-orchestrator/tasks.db`

### Essential Commands

```bash
# Initialize (once per project)
./tm init

# Create tasks
./tm add "Implement user authentication" --priority high
./tm add "Write tests for auth" --depends-on <task-id>

# View and manage tasks
./tm list                      # Show all tasks
./tm list --status pending     # Filter by status
./tm show <task-id>           # Show task details
./tm update <task-id> --status in_progress
./tm complete <task-id>

# Watch for updates (real-time monitoring)
./tm watch
```

### When to Use Task Orchestrator

**ALWAYS use Task Orchestrator when:**
- Starting a new feature or bug fix
- Breaking down complex work into subtasks
- Tracking dependencies between tasks
- Coordinating with other AI agents
- Managing project priorities

### Workflow Example

```bash
# 1. Start a new feature
FEATURE=$(./tm add "Implement payment processing" --priority critical)

# 2. Break it down into subtasks
API=$(./tm add "Create payment API endpoints" --depends-on $FEATURE)
UI=$(./tm add "Build payment UI components" --depends-on $API)
TESTS=$(./tm add "Write payment tests" --depends-on $UI)

# 3. Track progress
./tm update $API --status in_progress
# ... do the work ...
./tm complete $API

# 4. Check what's next
./tm list --status pending
```

### Multi-Agent Coordination

When working with multiple AI agents, use Task Orchestrator's three-channel communication:

```bash
# Set your agent identity
export TM_AGENT_ID="claude_main"

# Private notes (your internal reasoning)
./tm note <task-id> "Considering different authentication strategies"

# Share updates with team
./tm share <task-id> "Completed JWT implementation, ready for testing"

# Broadcast critical findings
./tm discover <task-id> "CRITICAL: Security vulnerability found in auth flow"

# Check shared context from other agents
./tm context <task-id>
```

### Task Status Meanings

- `pending` - Ready to work on
- `in_progress` - Currently being worked on
- `completed` - Finished successfully
- `blocked` - Waiting for dependencies
- `cancelled` - No longer needed

### Best Practices

1. **Create tasks for everything** - Even small items benefit from tracking
2. **Use clear, actionable titles** - "Fix login bug" not "bug"
3. **Set appropriate priorities** - critical > high > medium > low
4. **Update status regularly** - Keep the task list current
5. **Complete tasks when done** - This unblocks dependent tasks
6. **Use dependencies** - Link related tasks to maintain workflow
7. **Check notifications** - Run `./tm watch` to see unblocked tasks

### Working with Dependencies

```bash
# Tasks automatically block when dependencies exist
./tm add "Deploy to production" --depends-on task1 task2 task3

# View dependency chains
./tm list --has-deps

# Tasks automatically unblock when dependencies complete
./tm complete task1  # If this was the last dependency, dependent tasks unblock
```

### File References

Link tasks to specific code locations:

```bash
# Reference specific files and lines
./tm add "Fix type error" --file src/auth.ts:42
./tm add "Refactor validation" --file src/models/user.ts:100:150
```

### Export and Reporting

```bash
# Export task data for analysis
./tm export --format json > tasks.json
./tm export --format markdown > task-report.md
```

---

## Example CLAUDE.md Integration

You can also add task management rules to your workflow section:

### Development Workflow

1. **Before starting work**: Check existing tasks with `./tm list`
2. **Create task**: `./tm add "Description" --priority level`
3. **Start work**: `./tm update <id> --status in_progress`
4. **During work**: Add notes with `./tm note <id> "progress update"`
5. **Complete work**: `./tm complete <id>`
6. **Check next**: `./tm watch` for newly unblocked tasks