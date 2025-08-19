# 🚀 Task Orchestrator QuickStart Guide - Internal Development Teams

**Version:** 2.0.0  
**Release Date:** August 19, 2025  
**Purpose:** Multi-Agent Orchestration for Development Projects

## 🎯 What is Task Orchestrator?

Task Orchestrator is our production-ready, agent-to-agent communication system that enables sophisticated multi-agent coordination in Claude Code and other development environments. It provides:

- **Zero-dependency** task management with SQLite backend
- **Intelligent dependency resolution** for complex workflows
- **Multi-agent collaboration** with shared context
- **Real-time notifications** for team coordination
- **File-aware task tracking** for code-related work

## ⚡ 5-Minute QuickStart

### Step 1: Extract Package
```bash
# Extract the deployment package
tar -xzf task-orchestrator-v2.0.0-deploy.tar.gz
cd task-orchestrator

# Verify contents
ls -la
# You should see: tm, src/, CLAUDE.md, docs/
```

### Step 2: Initialize in Your Project
```bash
# Copy to your project root
cp -r task-orchestrator/* /path/to/your/project/

# Initialize the database
cd /path/to/your/project
./tm init

# Verify installation
./tm add "Test task"
./tm list
```

### Step 3: Configure Claude Code Integration
```bash
# Copy CLAUDE.md to your project (CRITICAL!)
cp CLAUDE.md /path/to/your/project/

# This file tells Claude Code agents how to use Task Orchestrator
# for multi-agent coordination in your project
```

### Step 4: Configure Claude Code Whitelist (ESSENTIAL!)
```json
# Add to your Claude Code configuration:
{
  "whitelisted_commands": [
    "./tm *"
  ]
}
```
**Without this, Claude will prompt for confirmation on every Task Orchestrator command!**  
See CLAUDE_CODE_WHITELIST.md for complete configuration options.

### Step 5: Test Multi-Agent Coordination
```bash
# Terminal 1 - Backend Agent
export TM_AGENT_ID="backend"
./tm add "Implement user API" -p high
./tm list
# Note the task ID (e.g., abc12345)

# Terminal 2 - Frontend Agent
export TM_AGENT_ID="frontend"
./tm join abc12345
./tm share abc12345 "Waiting for API specification"

# Terminal 1 - Backend shares update
./tm share abc12345 "API spec ready at docs/api.yaml"

# Both agents see shared context
./tm context abc12345
```

## 🔧 Core Commands for Development Teams

### 1. Task Creation with Dependencies
```bash
# Create parent task
EPIC=$(./tm add "Q4 Feature Release" -p critical | grep -o '[a-f0-9]\{8\}')

# Create dependent tasks
BACKEND=$(./tm add "Backend API" --depends-on $EPIC)
FRONTEND=$(./tm add "Frontend UI" --depends-on $BACKEND)
TESTS=$(./tm add "Integration Tests" --depends-on $FRONTEND)

# Tasks auto-block until dependencies complete
./tm show $BACKEND  # Status: blocked
./tm complete $EPIC  # Unblocks backend
./tm show $BACKEND  # Status: pending (ready to work)
```

### 2. File-Aware Task Tracking
```bash
# Link tasks to specific code files
./tm add "Fix authentication bug" --file src/auth/login.py:45:67
./tm add "Refactor database module" --file src/db/models.py:1:300

# Complete with impact review
./tm complete $TASK_ID --impact-review
# Notifies other agents working on same files
```

### 3. Multi-Agent Collaboration
```bash
# Join a task
./tm join $TASK_ID

# Share progress (visible to all)
./tm share $TASK_ID "Database schema complete"

# Private notes (only you see)
./tm note $TASK_ID "Check performance impact"

# Critical discovery (broadcasts to all)
./tm discover $TASK_ID "Security vulnerability found!"

# Sync point for coordination
./tm sync $TASK_ID "Ready for code review"

# View complete context
./tm context $TASK_ID
```

### 4. Advanced Filtering & Export
```bash
# Filter tasks
./tm list --status pending --assignee alice
./tm list --has-deps  # Tasks with dependencies

# Export for reporting
./tm export --format json > tasks.json
./tm export --format markdown > sprint_report.md

# Watch for notifications
./tm watch  # See recent events and discoveries
```

## 🤖 Claude Code Integration

### How Claude Agents Use Task Orchestrator

When Claude Code agents work in your project with CLAUDE.md present, they will:

1. **Automatically coordinate** through Task Orchestrator
2. **Share context** between different Claude sessions
3. **Track dependencies** across multi-agent work
4. **Notify each other** of important changes
5. **Maintain task state** across sessions

### Example Claude Workflow

```markdown
Human: "Create a new user authentication feature"

Claude (Session 1 - Architecture):
- Creates epic: `tm add "User Authentication Feature"`
- Breaks down: Creates subtasks with dependencies
- Shares design: `tm share $ID "Architecture design complete"`

Claude (Session 2 - Backend):
- Joins task: `tm join $ID`
- Sees context: `tm context $ID` (sees architecture)
- Updates: `tm share $ID "API endpoints ready"`
- Completes: `tm complete $BACKEND_ID`

Claude (Session 3 - Frontend):
- Automatically unblocked when backend completes
- Joins and implements UI
- Discovers issue: `tm discover $ID "CORS configuration needed"`

All agents are notified and can coordinate resolution!
```

## 📁 Project Structure Integration

### Recommended Setup
```
your-project/
├── tm                      # Task Orchestrator executable
├── src/
│   └── tm_production.py    # Core engine (required)
├── CLAUDE.md              # Agent instructions (CRITICAL!)
├── .task-orchestrator/    # Auto-created database directory
│   ├── tasks.db          # SQLite database
│   ├── contexts/         # Shared collaboration files
│   └── notes/            # Private agent notes
└── your-code/            # Your project files
```

### Environment Variables
```bash
# Set agent identity (optional, auto-generated if not set)
export TM_AGENT_ID="your_name_or_role"

# Custom database location (optional)
export TM_DB_PATH="/custom/path/tasks.db"

# Enable verbose output for debugging
export TM_VERBOSE=1
```

## 🎯 Common Development Scenarios

### Scenario 1: Sprint Planning
```bash
# Create sprint epic
SPRINT=$(./tm add "Sprint 24 - Payment System" -p high)

# Break down into stories
DESIGN=$(./tm add "Design payment flow" --depends-on $SPRINT)
GATEWAY=$(./tm add "Integrate payment gateway" --depends-on $DESIGN)
UI=$(./tm add "Build payment UI" --depends-on $GATEWAY)
TESTING=$(./tm add "Payment testing" --depends-on $UI)

# Assign to teams
./tm assign $DESIGN "design_team"
./tm assign $GATEWAY "backend_team"
./tm assign $UI "frontend_team"
```

### Scenario 2: Bug Fix Coordination
```bash
# Report bug with file reference
BUG=$(./tm add "Memory leak in cache handler" \
      --file src/cache/handler.py:234:256 -p critical)

# Multiple agents investigate
export TM_AGENT_ID="senior_dev"
./tm join $BUG
./tm share $BUG "Identified root cause: missing cleanup in destructor"

export TM_AGENT_ID="junior_dev"
./tm join $BUG
./tm note $BUG "Learning opportunity - document this pattern"

# Fix and review
./tm complete $BUG --impact-review
```

### Scenario 3: Feature Development
```bash
# Create feature with all aspects
FEATURE=$(./tm add "Add OAuth2 authentication")

# Technical tasks
DB=$(./tm add "OAuth2 database schema" --depends-on $FEATURE)
API=$(./tm add "OAuth2 API endpoints" --depends-on $DB)
UI=$(./tm add "OAuth2 login UI" --depends-on $API)

# Documentation tasks
DOCS=$(./tm add "OAuth2 documentation" --depends-on $UI)
EXAMPLES=$(./tm add "OAuth2 examples" --depends-on $DOCS)

# Track progress
./tm list --status in_progress  # What's being worked on
./tm list --status blocked       # What's waiting
./tm list --status completed     # What's done
```

## 🔥 Pro Tips

### 1. Use Dependencies Wisely
- Model actual workflow dependencies
- Auto-blocking prevents premature work
- Completion cascades unblock teams

### 2. Leverage File References
- Track exactly what code is affected
- Use impact review for critical changes
- Helps identify conflicts early

### 3. Collaborate Effectively
- `share` for team updates
- `note` for personal reminders
- `discover` for critical issues
- `sync` for coordination points

### 4. Filter and Export
- Use filters to focus on your work
- Export for stakeholder reports
- Watch notifications regularly

## 🐛 Troubleshooting

### Database Lock Issues
```bash
# If database is locked
rm .task-orchestrator/.lock
# Then retry operation
```

### WSL Performance
```bash
# Task Orchestrator auto-detects WSL
# If slow, manually enable WSL mode:
export TM_WSL_MODE=1
```

### Missing Dependencies
```bash
# Ensure Python 3.8+ is installed
python3 --version

# Ensure src/ directory is present
ls -la src/tm_production.py
```

## 📚 Additional Resources

- **Full Documentation**: See `docs/` directory
- **API Reference**: `docs/reference/API_REFERENCE.md`
- **Examples**: `docs/examples/` directory
- **Troubleshooting**: `docs/guides/TROUBLESHOOTING.md`

## 🚦 Getting Started Checklist

- [ ] Extract deployment package
- [ ] Copy files to project root
- [ ] Run `./tm init`
- [ ] Copy CLAUDE.md to project
- [ ] **ESSENTIAL: Configure Claude Code whitelist (see CLAUDE_CODE_WHITELIST.md)**
- [ ] Test with `./tm add "First task"`
- [ ] Set TM_AGENT_ID if desired
- [ ] Try multi-agent collaboration
- [ ] Configure team workflow

## 💡 Support

For questions or issues:
- Check TROUBLESHOOTING.md
- Review API_REFERENCE.md
- Submit bugs: `docs/support/issues/`
- Submit feedback: `docs/support/feedback/`
- See `docs/support/README.md` for templates

---

**Welcome to efficient multi-agent orchestration!**  
Task Orchestrator v2.0.0 - Production Ready