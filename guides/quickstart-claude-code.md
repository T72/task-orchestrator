# Task Orchestrator + Claude Code: QuickStart Guide

## 🚀 30-Second Setup

```bash
# 1. Clone the repository
git clone https://github.com/T72/task-orchestrator.git
cd task-orchestrator

# 2. Make executable and initialize
chmod +x tm
./tm init

# 3. Test it works
./tm add "My first task"
```

**That's it!** Task Orchestrator is now ready for use with Claude Code.

## 🤖 Claude Code Integration

### Basic Usage Pattern

When working with Claude Code on any project:

```bash
# 1. Navigate to your project
cd /your/project

# 2. Copy the task orchestrator
cp /path/to/task-orchestrator/tm ./tm
chmod +x tm

# 3. Initialize for this project
./tm init

# 4. Start creating tasks
./tm add "Implement user authentication"
```

### Claude Code Workflow Examples

#### Example 1: Breaking Down a Feature Request

**You tell Claude:**
```
"Help me build a user authentication system with JWT tokens"
```

**Claude uses Task Orchestrator:**
```bash
# Claude creates the main task
MAIN=$(./tm add "Build authentication system" -p high | grep -o '[a-f0-9]\{8\}')

# Claude breaks it down into subtasks
DB=$(./tm add "Design user database schema" --depends-on $MAIN | grep -o '[a-f0-9]\{8\}')
JWT=$(./tm add "Implement JWT token generation" --depends-on $DB | grep -o '[a-f0-9]\{8\}')
API=$(./tm add "Create REST endpoints" --depends-on $JWT | grep -o '[a-f0-9]\{8\}')
UI=$(./tm add "Build login UI" --depends-on $API | grep -o '[a-f0-9]\{8\}')

# Claude starts working
./tm update $DB --status in_progress
```

#### Example 2: Multi-Agent Development

**Scenario:** You want Claude to coordinate multiple specialized agents

```bash
# Orchestrator Claude sets up project
./tm add "Build e-commerce platform" --tag epic
./tm add "Database design" --tag backend --assignee db_specialist
./tm add "API development" --tag backend --assignee api_specialist
./tm add "Frontend components" --tag frontend --assignee ui_specialist

# Each specialist agent can then:
export TM_AGENT_ID="api_specialist"
./tm list --assignee api_specialist --status pending
./tm update task_id --status in_progress
```

#### Example 3: Tracking Progress Across Sessions

**First Claude session:**
```bash
./tm add "Refactor authentication module"
./tm share task_123 "Analyzed existing code, found 3 issues"
./tm note task_123 "Need to update JWT library version"
# Session ends
```

**Next Claude session (hours/days later):**
```bash
./tm context task_123  # Claude sees all previous context
./tm share task_123 "Fixed 2 of 3 issues"
./tm complete task_123
```

## 🎯 Key Commands for Claude Code

### Essential Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `tm init` | Initialize in new project | `./tm init` |
| `tm add` | Create a task | `./tm add "Fix bug"` |
| `tm list` | View all tasks | `./tm list --status pending` |
| `tm update` | Change task status | `./tm update abc123 --status in_progress` |
| `tm complete` | Mark task done | `./tm complete abc123` |
| `tm share` | Add team update | `./tm share abc123 "Found the issue"` |
| `tm context` | View task history | `./tm context abc123` |

### Advanced Features

```bash
# Add file references
./tm add "Fix auth bug" --file src/auth.py:42:45

# Create dependencies
./tm add "Deploy" --depends-on task1 --depends-on task2

# Filter by tags
./tm list --tag backend --status pending

# Export for reporting
./tm export --format markdown > tasks.md
```

## 🚀 Core Loop Workflow (NEW in v2.3)

Enhance your task management with quality tracking and success metrics:

### Complete Feature Development Workflow

```bash
# 1. Create task with success criteria and deadline
TASK_ID=$(./tm add "Build payment integration" \
  --criteria '[{"criterion":"All payment tests pass","measurable":"true"},
               {"criterion":"PCI compliance verified","measurable":"compliance_check == passed"}]' \
  --deadline "2025-12-31T23:59:59Z" \
  --estimated-hours 40 | grep -o '[a-f0-9]\{8\}')

# 2. Track progress throughout development
./tm progress $TASK_ID "10% - Researching payment providers"
./tm progress $TASK_ID "30% - Stripe SDK integrated"
./tm progress $TASK_ID "60% - Payment flow implemented"
./tm progress $TASK_ID "90% - Testing and compliance checks"

# 3. Complete with validation and summary
./tm complete $TASK_ID \
  --validate \
  --actual-hours 35 \
  --summary "Implemented Stripe integration with full PCI compliance, all tests passing"

# 4. Add quality feedback
./tm feedback $TASK_ID \
  --quality 5 \
  --timeliness 5 \
  --note "Delivered ahead of schedule with excellent documentation"

# 5. View team metrics
./tm metrics --feedback
# Output: Average quality: 4.8/5, Success rate: 95%
```

### Quick Bug Fix Workflow

```bash
# Create bug fix task with criteria
BUG=$(./tm add "Fix login timeout issue" \
  --criteria '[{"criterion":"Users can stay logged in 24h","measurable":"true"}]' \
  --priority critical \
  --estimated-hours 2 | grep -o '[a-f0-9]\{8\}')

# Track investigation
./tm progress $BUG "Found issue: session expires after 1h instead of 24h"

# Complete with validation
./tm complete $BUG --validate --actual-hours 1.5 \
  --summary "Fixed session timeout configuration"
```

### Enable/Disable Core Loop Features

```bash
# View current configuration
./tm config --show

# Enable only what you need
./tm config --enable feedback
./tm config --enable success-criteria
./tm config --disable telemetry

# Or use minimal mode (no Core Loop features)
./tm config --minimal-mode
```

### First-Time Migration

If upgrading from v2.2 or earlier:

```bash
# Backup first (always!)
cp -r ~/.task-orchestrator ~/.task-orchestrator.backup

# Apply Core Loop migration
./tm migrate --apply

# Verify success
./tm migrate --status
# Output: Applied migrations: 001 | Up to date: Yes
```

## 🔧 Configuration for Claude Code

### ⚠️ ESSENTIAL: Claude Code Whitelist Setup

**BEFORE using Task Orchestrator with Claude Code, you MUST configure command whitelisting to avoid confirmation prompts on every command:**

```json
{
  "whitelisted_commands": [
    "./tm *"
  ]
}
```

**📋 Complete whitelist configuration:** See [CLAUDE_CODE_WHITELIST.md](../../deploy/CLAUDE_CODE_WHITELIST.md) for:
- Multiple security levels (permissive to restrictive)
- Environment-specific configurations
- Testing instructions
- Troubleshooting guide

### Environment Variables (Optional)

```bash
# Set agent identity (otherwise auto-generated)
export TM_AGENT_ID="claude_main"

# Custom database location (if needed)
export TM_DB_PATH=".task-orchestrator/tasks.db"
```

### Best Practices with Claude Code

1. **Always initialize first**: Run `./tm init` in each new project
2. **Use clear task titles**: "Fix login bug" not just "Bug"
3. **Add file references**: Helps Claude navigate large codebases
4. **Use dependencies**: Ensures logical task flow
5. **Share discoveries**: Use `tm discover` for important findings

## 📋 Common Claude Code Scenarios

### Scenario 1: Bug Fixing Session

```bash
# Claude identifies the bug
BUG=$(./tm add "Fix login timeout issue" -p critical)
./tm update $BUG --file src/auth/session.js:234

# Claude works on it
./tm update $BUG --status in_progress
./tm share $BUG "Issue: Session timeout not properly cleared"

# Claude fixes it
./tm share $BUG "Fixed: Added clearTimeout in cleanup"
./tm complete $BUG
```

### Scenario 2: Feature Implementation

```bash
# Claude plans the feature
FEATURE=$(./tm add "Add dark mode toggle")
./tm add "Create theme context" --depends-on $FEATURE
./tm add "Add toggle component" --depends-on $FEATURE
./tm add "Update CSS variables" --depends-on $FEATURE

# Claude implements step by step
./tm list --depends-on $FEATURE
```

### Scenario 3: Code Review Preparation

```bash
# Claude prepares for review
./tm add "Prepare PR for review" --tag review
./tm share task_id "Fixed linting issues"
./tm share task_id "Added unit tests"
./tm share task_id "Updated documentation"
./tm complete task_id
```

## 🚨 Troubleshooting

### "Command not found"
```bash
# Make sure it's executable
chmod +x tm
# Or use Python directly
python3 tm add "Task"
```

### "Not in a git repository"
```bash
# Initialize git first
git init
# Then initialize task orchestrator
./tm init
```

### "Database locked"
```bash
# Wait a moment and retry, or increase timeout
export TM_LOCK_TIMEOUT=30
```

## 💡 Pro Tips

1. **Batch Operations**: Create multiple tasks at once
   ```bash
   for task in "Design API" "Implement backend" "Create UI"; do
     ./tm add "$task"
   done
   ```

2. **Task Templates**: Use consistent patterns
   ```bash
   ./tm add "[BUG] Login fails with special characters" --tag bug --priority high
   ./tm add "[FEATURE] Add password reset" --tag feature --priority medium
   ```

3. **Progress Tracking**: Use status progression
   ```bash
   pending → analyzing → in_progress → testing → completed
   ```

## 📚 Next Steps

- Read the [User Guide](USER_GUIDE.md) for complete documentation
- Check [Examples](../examples/) for real-world usage patterns
- See [Troubleshooting](TROUBLESHOOTING.md) for common issues
- Review [API Reference](../reference/API_REFERENCE.md) for all commands

## 🎉 You're Ready!

Start using Task Orchestrator with Claude Code to manage complex projects efficiently. The system handles all the complexity while you focus on building great software!

---

**Need help?** Check our [documentation](../../README.md) or file an issue on [GitHub](https://github.com/T72/task-orchestrator/issues).