# Task Orchestrator

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Tests](https://img.shields.io/badge/tests-passing-green.svg)](#testing)
[![Version](https://img.shields.io/badge/version-2.0.1-demo-blue.svg)](https://github.com/T72/task-orchestrator/releases)

## 🎯 WHY: Our Mission

**We believe that complex software development should be orchestrated, not chaotic.**

In today's world of parallel development, multi-agent AI systems, and distributed teams, task coordination has become the critical bottleneck. We exist to transform task management from a burden into a competitive advantage.

### The Problem We Solve

Modern development faces unprecedented coordination challenges:
- **Parallel Work Conflicts**: Multiple developers and AI agents working simultaneously create dependency chaos
- **Context Loss**: Critical information gets buried in tickets, chat, and disconnected tools
- **Integration Friction**: Teams waste 30% of their time on coordination overhead
- **Brittle Workflows**: One blocked task cascades into project-wide delays

### Our Purpose

Task Orchestrator eliminates coordination waste by providing a single source of truth for task dependencies, enabling teams and AI agents to work in perfect harmony. We maximize delivered value by focusing on what matters: getting work done, not managing it.

## 🚀 HOW: Our Approach

We achieve orchestration excellence through **LEAN principles** and **radical simplicity**:

### Core Principles

1. **Zero Waste Philosophy**
   - No external dependencies (Python stdlib only)
   - No configuration overhead (works out of the box)
   - No learning curve (Unix-style CLI)

2. **Value-First Design**
   - Every feature must eliminate coordination waste
   - Automatic dependency resolution prevents blocking
   - File-level tracking connects tasks to actual code

3. **Continuous Flow**
   - Lock-free concurrent access for parallel work
   - Instant notification when blockers clear
   - Seamless handoffs between agents and developers

4. **Built-In Resilience**
   - ACID-compliant SQLite for data integrity
   - Automatic recovery from failures
   - Cross-worktree synchronization

## 🛠️ WHAT: The Task Orchestrator

A lightweight, powerful orchestration system that transforms how teams and AI agents coordinate work.

### Key Capabilities

- **🔄 Smart Dependencies**: Automatic resolution, circular prevention, instant unblocking
- **🔒 Concurrent Safe**: ACID-compliant with safe multi-agent access
- **📁 Code-Aware**: Direct file and line number references for precise context
- **🌐 Cross-Platform**: Linux, macOS, Windows - zero configuration needed
- **📊 Export Ready**: JSON and Markdown for seamless tool integration
- **🏷️ Flexible Organization**: Tags, priorities, and custom metadata

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

That's it! You're orchestrating. No configuration, no dependencies, just results.

## 💡 Core Usage Patterns

### Eliminate Blocking - Dependency Chains
```bash
# Create a feature workflow that never blocks
API=$(./tm add "Create API endpoints" | grep -o '[a-f0-9]\{8\}')
UI=$(./tm add "Build UI" --depends-on $API | grep -o '[a-f0-9]\{8\}')
TEST=$(./tm add "Integration tests" --depends-on $UI | grep -o '[a-f0-9]\{8\}')

# Complete API work → UI automatically unblocks → Tests automatically unblock
./tm complete $API --impact-review
```

### Maximize Context - File-Aware Tasks
```bash
# Connect tasks directly to code
./tm add "Fix memory leak" --file src/cache.py:234 --priority critical
./tm add "Refactor auth module" --file src/auth.py:100:250

# See exactly what needs attention
./tm list --has-files
```

### Enable Parallel Work - Multi-Agent Coordination
```bash
# Agent 1: Create main task
MAIN=$(./tm add "User dashboard" | grep -o '[a-f0-9]\{8\}')

# Agent 2: Pick up and work
./tm assign $MAIN agent2
./tm update $MAIN --status in_progress

# Agent 3: Get notified when ready
./tm watch  # Real-time notifications when blockers clear
```

## 📚 Documentation & Resources

### Essential Guides
- **[User Guide](docs/guides/user-guide.md)** - Complete manual with best practices
- **[Developer Guide](docs/guides/developer-guide.md)** - Architecture and contribution guide
- **[API Reference](docs/reference/api-reference.md)** - Complete technical documentation
- **[Troubleshooting](docs/guides/troubleshooting.md)** - Solutions to common issues
- **[Claude Code Integration](deploy/claude-code-whitelist.md)** - **REQUIRED** for Claude Code users

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

## 🌟 Join the Movement

Task Orchestrator isn't just a tool—it's a philosophy. We believe that:

- **Coordination should be invisible**: Focus on work, not workflow
- **Dependencies should resolve themselves**: No manual tracking
- **Context should travel with tasks**: Never lose critical information
- **Simplicity beats complexity**: Every time, without exception

**Ready to eliminate coordination waste?** Star us on [GitHub](https://github.com/T72/task-orchestrator) and join developers worldwide who are orchestrating their way to success.

---

*"We don't manage tasks. We orchestrate success."*

**Task Orchestrator v2.0.1** | Built with purpose, delivered with passion.
