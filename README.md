# Task Orchestrator

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Tests](https://img.shields.io/badge/tests-passing-green.svg)](#testing)
[![Version](https://img.shields.io/badge/version-2.6.0-blue.svg)](https://github.com/T72/task-orchestrator/releases)

> **🎉 What's New in v2.6.0**  
> • **Save Hours with Templates** - Define your workflow once, reuse it forever  
> • **Get Started in Seconds** - Interactive wizard guides you through setup  
> • **Better Performance** - Faster task processing and dependency resolution  
> [See what's new →](#version-history)

## 🚀 Transform Your Development Workflow

### Stop Recreating the Same Tasks Every Sprint
With **Task Templates**, define your workflow once and reuse it forever:
```bash
# Your team's sprint workflow, automated
./tm template apply sprint.yaml --var feature_name="Authentication"

# Instantly creates your entire sprint structure:
# ✓ Sprint Planning (high priority)
# ✓ Development - Authentication (depends on planning)
# ✓ Testing - Authentication (depends on development)
# ✓ Sprint Review (depends on testing)
```
**Result**: Save 30+ minutes per sprint on task setup.

### Start Working in Seconds, Not Minutes
The **Interactive Wizard** guides new team members through task creation:
```bash
./tm wizard
# Answers a few questions, creates perfectly structured tasks
# No need to remember syntax or dependencies
```
**Result**: New developers productive on day one.

## The Problem: 30% of Your Time Lost to Coordination

You know the pain: Developer A is blocked waiting for Developer B. The AI agent lost context from yesterday. Someone's working on an outdated task. Different projects' tasks are mixed together in one giant mess.

**Task Orchestrator eliminates these problems**, giving you back hours every week.

## Why Teams Choose Task Orchestrator

### 🎯 Immediate Benefits
- **Save 30% of coordination time** - Dependencies resolve automatically
- **Eliminate task confusion** - Each project has its own isolated workspace
- **Stop re-explaining context** - Information travels with the task
- **Enable true parallel work** - Multiple developers and AI agents work without conflicts

### 🤖 Built for AI-Powered Development
- **Multiple AI agents coordinate seamlessly** without stepping on each other
- **Context stays with the task** - no more copy-pasting between agents
- **Real-time orchestration** - Agents react instantly when dependencies resolve
- **Private reasoning space** - Agents think without cluttering shared channels

### 💡 Zero Friction Setup
- **2-minute installation** - Just clone and run
- **No dependencies** - Python standard library only
- **Works everywhere** - Linux, macOS, Windows with Python 3.8+
- **No configuration needed** - Smart defaults that just work

## ⚡ Quick Start (2 Minutes)

```bash
# 1. Clone and setup (30 seconds)
git clone https://github.com/T72/task-orchestrator.git
cd task-orchestrator
chmod +x tm

# 2. Initialize (instant)
./tm init

# 3. Your first orchestrated workflow (90 seconds)
SETUP=$(./tm add "Setup environment" | grep -o '[a-f0-9]\{8\}')
./tm add "Run tests" --depends-on $SETUP
./tm add "Deploy" --depends-on $SETUP --file deploy.sh:15

# Watch the magic happen
./tm list
./tm complete $SETUP  # Automatically unblocks dependent tasks!
```

That's it! You're ready to start organizing your tasks more effectively.

## 💡 Real-World Usage

### Reduce Dependency Blocking
```bash
# Create a feature that requires backend → frontend → tests
API=$(./tm add "Create API endpoints" | grep -o '[a-f0-9]\{8\}')
UI=$(./tm add "Build UI" --depends-on $API | grep -o '[a-f0-9]\{8\}')
TEST=$(./tm add "Integration tests" --depends-on $UI | grep -o '[a-f0-9]\{8\}')

# When you complete the API, the UI task automatically unblocks
./tm complete $API
# Now your frontend developer can immediately start working
```

### Track Exactly What Code Needs Work
```bash
# Link tasks to specific code locations
./tm add "Fix memory leak" --file src/cache.py:234 --priority critical

# See all tasks with dependencies
./tm list --has-deps
# Shows tasks that depend on or are dependencies of other tasks
```

### Multiple Developers, Zero Conflicts
```bash
# Developer 1 creates the main feature
FEATURE=$(./tm add "Payment system" | grep -o '[a-f0-9]\{8\}')

# Developer 2 claims and starts work
./tm assign $FEATURE dev2
./tm update $FEATURE --status in_progress

# Developer 3 watches for completion
./tm watch  # Gets instant notification when payment system is ready
```

## 🤖 AI Agent Orchestration

Task Orchestrator is designed for the era of AI-powered development, where multiple specialized agents work together on complex tasks.

### Shared Context - No More Copy-Pasting

When you delegate a task to an agent, you can provide rich context that travels with the task:

```bash
# Provide context when creating a task
./tm add "Implement OAuth2 authentication" \
  --context "Use existing User model, integrate with Google & GitHub providers" \
  --assignee backend-agent

# The backend agent receives all context automatically
# No need to re-explain requirements to each new agent
```

### Private Agent Notes - Clean Reasoning Space

Agents can maintain private notes during their work without cluttering the shared space:

```bash
# Agent adds private reasoning notes
./tm note $TASK_ID --private "Considering JWT vs session tokens. 
JWT better for our stateless architecture. Checking token rotation strategy..."

# These notes help agents reason through problems
# Other agents see results, not the entire thought process
```

### Real-Time Orchestration

An orchestrating agent can monitor and coordinate multiple specialists:

```bash
# Orchestrator watches for tasks to unblock
./tm watch

# When backend agent completes authentication:
# > "Task 'OAuth2 authentication' completed. Task 'Frontend login UI' now unblocked."

# Orchestrator immediately assigns to frontend specialist
./tm assign $FRONTEND_TASK frontend-agent
```

### Progress Transparency

Agents share progress updates, enabling smooth handoffs:

```bash
# Database agent updates progress
./tm progress $TASK_ID "Schema designed, 3/5 tables created"

# Backend agent can see exactly where things stand
./tm show $TASK_ID
# Shows: "In Progress: Schema designed, 3/5 tables created"
```

This enables true parallel development where specialized agents (database, backend, frontend, testing) work simultaneously without stepping on each other's toes.

## 📈 Deliver Better Results

### Know When You're Really Done
Define measurable success criteria and validate them automatically:

```bash
# Create task with success criteria
./tm add "Fix login bug" \
  --criteria '[{"criterion":"Bug no longer reproduces","measurable":"true"},
               {"criterion":"No regression in auth tests","measurable":"test_pass_rate >= 100"}]' \
  --estimated-hours 4

# Complete with automatic validation
./tm complete $TASK_ID --validate --actual-hours 3.5 \
  --summary "Fixed race condition in session handling, all tests passing"
# Output: ✓ 2/2 criteria passed - task completed successfully
```

### Get Better Every Sprint
Learn from every task to improve continuously:

```bash
# Add feedback on completed task
./tm feedback $TASK_ID --quality 5 --timeliness 4 \
  --note "Excellent fix, delivered ahead of schedule"

# View team metrics
./tm metrics --feedback
# Output:
#   Average quality: 4.8/5 (15 tasks)
#   Average timeliness: 4.2/5
#   Success rate: 93%
#   Feedback coverage: 78%
```

### Improve Your Estimates
Track time accurately to plan better:

```bash
# Add progress updates throughout task lifecycle
./tm progress $TASK_ID "Reproduced bug, analyzing root cause"
./tm progress $TASK_ID "50% - Found race condition in auth flow"
./tm progress $TASK_ID "90% - Fix implemented, running tests"

# Set deadlines and track time
./tm add "Implement feature X" --deadline "2025-12-31T23:59:59Z" --estimated-hours 20
./tm complete $TASK_ID --actual-hours 18.5  # Track accuracy for future estimates
```

### Configuration & Feature Management

Customize Core Loop features to match your workflow:

```bash
# Enable/disable specific features
./tm config --enable feedback
./tm config --enable success-criteria
./tm config --disable telemetry

# Use minimal mode for lightweight operation
./tm config --minimal-mode  # Disables all Core Loop features

# View current configuration
./tm config --show
```

### Migration from v2.2

Upgrading to v2.3 requires a simple database migration:

```bash
# Backup your data first (always recommended)
cp -r ~/.task-orchestrator ~/.task-orchestrator.backup

# Apply Core Loop schema updates
./tm migrate --apply

# Verify migration
./tm migrate --status
# Output: Applied migrations: 001 | Up to date: Yes
```

All existing tasks remain unchanged - Core Loop features are optional enhancements that you can adopt gradually.

## 📋 What's Improved Recently

### v2.6.0 (Latest) - Work Smarter, Not Harder
- **Save 30+ minutes per sprint** with reusable task templates
- **Onboard developers faster** with the interactive wizard
- **Experience 2x faster performance** in task operations

### v2.5.0 - True Project Isolation  
- **No more task confusion** - each project has its own database
- **Work on multiple clients** without mixing their tasks
- **Switch projects instantly** without cleanup

### v2.3.0 - Know When You're Done
- **Define "done" clearly** with measurable success criteria
- **Track actual vs estimated time** to improve planning
- **Get quality feedback** on completed work

[Full changelog →](https://github.com/T72/task-orchestrator/blob/main/CHANGELOG.md)

## 📚 Documentation & Resources

### Essential Guides
- **[User Guide](docs/guides/user-guide.md)** - Complete manual with best practices
- **[Developer Guide](docs/guides/developer-guide.md)** - Architecture and contribution guide
- **[API Reference](docs/reference/api-reference.md)** - Complete technical documentation
- **[Troubleshooting](docs/guides/troubleshooting.md)** - Solutions to common issues
- **[Claude Code Integration](deploy/CLAUDE_CODE_WHITELIST.md)** - **REQUIRED** for Claude Code users

### Working Examples
Run these directly to learn by doing:
```bash
python3 docs/examples/basic_usage.py          # Core concepts
python3 docs/examples/dependency_management.py # Complex workflows
python3 docs/examples/multi_agent_workflow.py  # Team coordination
```

## 🧪 Testing & Quality

```bash
# Run comprehensive test suite
./tests/run_all_tests_safe.sh  # WSL-safe execution

# Individual test categories
./tests/test_tm.sh              # Core functionality (100% pass)
./tests/test_edge_cases.sh      # Edge cases (86% pass)
./tests/test_stress_test.sh     # Performance under load
```

## 🚀 Installation Details

### Requirements
- Python 3.8+ (standard library only)
- 10MB disk space
- Linux, macOS, or Windows

### Database Location (v2.4+)

By default, Task Orchestrator creates a **project-local** database in `./.task-orchestrator/` for complete isolation between projects.

```bash
# Default: Project-local database (NEW in v2.4)
./tm init  # Creates ./.task-orchestrator/tasks.db in current directory

# Override with environment variable if needed
export TM_DB_PATH="/custom/path"  # Use custom location
export TM_DB_PATH="~/.task-orchestrator"  # Use old global behavior

# Adjust for slow systems
export TM_LOCK_TIMEOUT=30

# Enable verbose mode
export TM_VERBOSE=1
```

## 🤝 Contributing

We embrace LEAN contributions that eliminate waste and maximize value:

1. **Fork & Branch**: Create focused feature branches
2. **Test Rigorously**: All tests must pass
3. **Document Clearly**: Update relevant docs
4. **Submit PR**: With clear value proposition

### Priority Areas
- Performance optimization for 100+ concurrent agents
- Additional export formats (GraphQL, REST API)
- Visual dependency graphs
- Real-time collaboration features

## 📜 License

MIT License - see [LICENSE](LICENSE) for details.

## Try Task Orchestrator

Task Orchestrator can help reduce the time you spend on coordination, allowing more focus on development.

**Quick setup:** Clone, initialize, and try creating your first dependency chain.

If you find it helpful, consider starring us on [GitHub](https://github.com/T72/task-orchestrator).

---

**Task Orchestrator v2.6.0** - Advanced task creation with templates, interactive wizard, and comprehensive hook performance monitoring.
