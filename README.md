# Task Orchestrator

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Tests](https://img.shields.io/badge/tests-passing-green.svg)](#testing)
[![Version](https://img.shields.io/badge/version-2.0.1--demo-blue.svg)](https://github.com/T72/task-orchestrator/releases)

## Stop Fighting Task Dependencies

**Many teams report spending up to 30% of development time on coordination. Task Orchestrator can help significantly reduce this overhead.**

When multiple developers and AI agents work on the same codebase, coordination becomes challenging. Tasks often block each other. Context can get lost. Simple changes sometimes cascade into larger delays.

Task Orchestrator helps by automatically managing dependencies, unblocking work when prerequisites complete, and maintaining context across your team.

## What You Get

- **Reduced Blocking**: Dependencies resolve automatically - when task A completes, task B can be unblocked
- **Better Context**: Tasks carry shared context between agents, eliminating re-explanation
- **AI Agent Collaboration**: Specialized agents can share progress, maintain private notes, and coordinate seamlessly
- **Improved Parallel Work**: Multiple developers and AI agents work together without conflicts
- **Real-Time Orchestration**: Watch command enables instant coordination when tasks unblock
- **Minimal Setup**: Simple configuration, Python standard library only
- **Cross-Platform**: Works on Linux, macOS, and Windows with Python 3.8+

## ⚡ Quick Start (2 Minutes)

```bash
# 1. Clone and setup (30 seconds)
git clone https://github.com/T72/task-orchestrator.git
cd task-orchestrator
chmod +x tm  # Make executable (Linux/Mac) or use: python3 tm

# 2. Initialize (instant)
./tm init  # Or: python3 tm init

# 3. Your first orchestrated workflow (90 seconds)
SETUP=$(./tm add "Setup environment")  # Returns task ID: abc12345
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

# See all tasks affecting specific files
./tm list --has-files
# Shows: "Fix memory leak - src/cache.py:234" with direct line reference
```

### Multiple Developers, Zero Conflicts
```bash
# Developer 1 creates the main feature
FEATURE=$(./tm add "Payment system")

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

## 📚 Documentation & Resources

### Essential Guides
- **[User Guide](docs/user-guide.md)** - Complete manual with best practices
- **[Developer Guide](docs/developer-guide.md)** - Architecture and contribution guide
- **[API Reference](docs/reference/api-reference.md)** - Complete technical documentation
- **[Troubleshooting](docs/troubleshooting.md)** - Solutions to common issues
- **[Claude Code Quick Start](docs/quickstart-claude-code.md)** - Quick setup for Claude Code users

### Claude Code Integration

To enable optimal Task Orchestrator usage with Claude Code in your projects:

1. **Add to CLAUDE.md**: Include Task Orchestrator instructions in your project's CLAUDE.md file
2. **Choose a template**:
   - **[Full Template](docs/examples/claude-md-template.md)** - Comprehensive instructions with all features
   - **[Minimal Template](docs/examples/claude-md-minimal.md)** - Just the essentials for quick setup
3. **Whitelist commands**: Add `./tm *` to your whitelisted commands

This ensures Claude Code knows exactly how to leverage Task Orchestrator for your specific needs.

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

### Advanced Setup
```bash
# Custom database location
export TM_DB_PATH="/path/to/tasks.db"

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

**Task Orchestrator v2.0.1** - A simple tool to help manage task dependencies.
