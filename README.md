# Task Orchestrator

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Tests](https://img.shields.io/badge/tests-passing-green.svg)](#testing)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/T72/task-orchestrator/releases)

A powerful, lightweight task management and dependency orchestration system designed for developers, AI agents, and project teams working in parallel across complex workflows.

## Why Task Orchestrator?

- 🚀 **Zero Dependencies**: Built with Python's standard library only
- 🔄 **Smart Dependencies**: Automatic dependency resolution and circular dependency prevention  
- 🔒 **Concurrent Safe**: Database locking prevents data corruption during parallel access
- 📁 **File Linking**: Reference specific files and line numbers for code-related tasks
- 🏷️ **Flexible Tagging**: Organize and filter tasks with custom tags
- 📊 **Export Ready**: JSON and Markdown export for integration with other tools
- 🌐 **Cross-Platform**: Works seamlessly on Linux, macOS, and Windows

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Features](#features)
- [Usage](#usage)
- [Configuration](#configuration)
- [Documentation](#documentation)
- [Examples](#examples)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

## Installation

### System Requirements
- Python 3.8 or higher
- 10MB disk space
- Any Unix-like system (Linux, macOS) or Windows

### Quick Install
```bash
# Clone the repository
git clone https://github.com/T72/task-orchestrator.git
cd task-orchestrator

# Make the script executable (Linux/macOS)
chmod +x tm

# Initialize the database
./tm init

# Verify installation
./tm --version
```

## Quick Start

```bash
# Add your first task
./tm add "Set up development environment" --priority high

# Add a task with file reference
./tm add "Fix authentication bug" --file src/auth.py:45

# Create a dependency chain
SETUP_TASK=$(./tm add "Install dependencies" | grep -o '[a-f0-9]\{8\}')
./tm add "Run tests" --depends-on $SETUP_TASK

# List all tasks
./tm list

# Update task status
./tm update $SETUP_TASK --status in_progress

# Complete the task
./tm complete $SETUP_TASK
```

## Features

- **Cross-worktree synchronization**: Share tasks across all git worktrees
- **Dependency management**: Block tasks until dependencies complete
- **File references**: Track which files are associated with tasks
- **Notifications**: Get alerted when blocked tasks unblock or when your tasks are impacted
- **Unix-style CLI**: Simple, composable commands
- **Concurrent access**: Safe multi-agent access with file locking
- **Export capabilities**: JSON and Markdown export formats

## Installation

1. Place the `tm` script in your repository
2. Make it executable: `chmod +x tm`
3. Initialize the database: `./tm init`

The task orchestrator stores data in `.task-orchestrator/tasks.db` at your repository root.

## Usage

### Basic Commands

```bash
# Initialize the task orchestrator
tm init

# Add a simple task
tm add "Fix the login bug"

# Add a task with details
tm add "Refactor authentication" -d "Move auth logic to separate module" -p high

# List all tasks
tm list

# Show task details
tm show abc12345

# Update task status
tm update abc12345 --status in_progress

# Complete a task
tm complete abc12345

# Assign task to an agent
tm assign abc12345 agent_name
```

### Dependencies

```bash
# Add a task that depends on another
tm add "Deploy to production" --depends-on abc12345

# Tasks with unmet dependencies are automatically blocked
# When dependencies complete, blocked tasks become pending
```

### File References

```bash
# Add a task with file references
tm add "Fix type error" --file src/auth.py:42

# Reference a range of lines
tm add "Refactor function" --file src/utils.py:100:150
```

### Notifications

```bash
# Check for notifications
tm watch

# Complete a task with impact review
# This notifies other agents if their tasks reference the same files
tm complete abc12345 --impact-review
```

### Filtering and Search

```bash
# List only pending tasks
tm list --status pending

# List tasks assigned to specific agent
tm list --assignee agent123

# List tasks with dependencies
tm list --has-deps
```

### Export

```bash
# Export as JSON
tm export --format json > tasks.json

# Export as Markdown
tm export --format markdown > tasks.md
```

## Task Statuses

- **pending**: Ready to be worked on
- **in_progress**: Currently being worked on
- **completed**: Task is done
- **blocked**: Waiting for dependencies
- **cancelled**: Task was cancelled

## Priority Levels

- **low**: Nice to have
- **medium**: Normal priority (default)
- **high**: Important task
- **critical**: Urgent, blocks other work

## Architecture

### Storage
- SQLite database for ACID compliance
- File-based locking for concurrent access
- Stored in `.task-orchestrator/` at repository root
- Accessible from all git worktrees

### Agent Identification
- Each agent has a unique ID based on process, worktree, and user
- Agents can see all tasks but get personalized notifications

### Dependency Resolution
- Automatic status propagation when dependencies complete
- Prevents circular dependencies
- Visual dependency graph available

## Examples

### Scenario 1: Parallel Feature Development

```bash
# Agent 1: Create main feature task
MAIN=$(tm add "Implement user dashboard" -p high | grep -o '[a-f0-9]\{8\}')

# Agent 1: Break down into subtasks
API=$(tm add "Create dashboard API endpoints" --depends-on $MAIN | grep -o '[a-f0-9]\{8\}')
UI=$(tm add "Build dashboard UI components" --depends-on $API | grep -o '[a-f0-9]\{8\}')
TESTS=$(tm add "Write dashboard tests" --depends-on $UI | grep -o '[a-f0-9]\{8\}')

# Agent 2: Pick up the API task
tm update $API --status in_progress
tm assign $API agent2

# Agent 2: Complete API work
tm complete $API --impact-review
# This automatically unblocks the UI task
```

### Scenario 2: Bug Fix with File Tracking

```bash
# Agent 1: Found a bug while working on something else
tm add "Memory leak in cache handler" --file src/cache.py:234 -p high --tag bug

# Agent 2: Later picks this up
tm list --tag bug
tm show <task_id>  # See exact file and line reference
```

### Scenario 3: Impact Analysis

```bash
# Agent 1: Completes a refactoring task
tm complete refactor_task --impact-review

# Agent 2: Gets notified
tm watch
# "Task refactor_task completed with changes to src/auth.py"
# Agent 2 knows their auth-related task might be affected
```

## Configuration

Task Orchestrator creates a `.task-orchestrator/` directory in your project root containing:

- `tasks.db`: SQLite database with all task data
- `config.json`: Configuration settings (auto-generated)
- `.lock`: Process lock file for concurrent access safety

### Environment Variables

- `TM_DB_PATH`: Override default database location
- `TM_LOCK_TIMEOUT`: Database lock timeout in seconds (default: 10)
- `TM_VERBOSE`: Enable verbose logging (set to `1`)

### Custom Configuration

```bash
# Use custom database location
export TM_DB_PATH="/path/to/custom/tasks.db"

# Increase lock timeout for slow systems
export TM_LOCK_TIMEOUT=30

# Enable verbose logging
export TM_VERBOSE=1
```

## Documentation

Task Orchestrator comes with comprehensive documentation for both users and developers:

### 📚 Complete Documentation Suite

- **[USER_GUIDE.md](docs/guides/USER_GUIDE.md)** - Complete user manual with tutorials, best practices, and advanced features
- **[DEVELOPER_GUIDE.md](docs/guides/DEVELOPER_GUIDE.md)** - Architecture overview, contributing guidelines, and extension development
- **[API_REFERENCE.md](docs/reference/API_REFERENCE.md)** - Complete API documentation for all classes, methods, and CLI commands
- **[TROUBLESHOOTING.md](docs/guides/TROUBLESHOOTING.md)** - Common issues, solutions, and debugging techniques
- **[CLAUDE_CODE_WHITELIST.md](deploy/CLAUDE_CODE_WHITELIST.md)** - **ESSENTIAL:** Claude Code command whitelist configuration (required for seamless operation)

### 🎯 Quick Access

| Document | Purpose | Audience |
|----------|---------|----------|
| [USER_GUIDE.md](docs/guides/USER_GUIDE.md) | Learn to use Task Orchestrator effectively | End users, team leads |
| [DEVELOPER_GUIDE.md](docs/guides/DEVELOPER_GUIDE.md) | Contribute to and extend the codebase | Developers, contributors |
| [API_REFERENCE.md](docs/reference/API_REFERENCE.md) | Complete technical reference | Developers, integrators |
| [TROUBLESHOOTING.md](docs/guides/TROUBLESHOOTING.md) | Solve problems and optimize performance | All users |
| [CLAUDE_CODE_WHITELIST.md](deploy/CLAUDE_CODE_WHITELIST.md) | **REQUIRED:** Claude Code integration setup | **All Claude Code users** |

## Examples

Learn by example with our comprehensive collection of working code samples:

### 🏃‍♂️ Running Examples

All examples are located in `docs/examples/` and can be run directly:

```bash
# Basic usage patterns
python3 docs/examples/basic_usage.py

# Advanced dependency management
python3 docs/examples/dependency_management.py

# Multi-agent coordination
python3 docs/examples/multi_agent_workflow.py

# Claude Code integration
python3 docs/examples/claude_integration.py

# Enterprise-scale scenarios
python3 docs/examples/large_scale_tasks.py
```

### 📝 Example Categories

| Script | Focus Area | Use Cases |
|--------|------------|-----------|
| `basic_usage.py` | Core functionality | Task creation, updates, dependencies |
| `dependency_management.py` | Complex workflows | Feature development, release processes |
| `multi_agent_workflow.py` | Team coordination | Multi-developer projects, role-based work |
| `claude_integration.py` | AI assistance | Code analysis, automated task creation |
| `large_scale_tasks.py` | Enterprise deployment | Hundreds of tasks, performance at scale |

### 💡 Learning Path

1. **Start here**: Run `basic_usage.py` to understand core concepts
2. **Dependencies**: Explore `dependency_management.py` for workflow patterns  
3. **Team work**: Try `multi_agent_workflow.py` for collaboration scenarios
4. **AI integration**: Use `claude_integration.py` for Claude Code features
5. **Scale up**: Run `large_scale_tasks.py` for enterprise patterns

Each example includes detailed explanations and demonstrates real-world scenarios you can adapt for your projects.

## Testing

Our comprehensive test suite ensures reliability and quality:

### Run Tests
```bash
# Basic functionality tests (must pass 100%)
./test_tm.sh

# Edge case tests (currently 86% pass rate)
./test_edge_cases.sh

# Stress tests for performance
./stress_test.sh

# Validation tests
python3 test_validation.py
```

### Test Results Summary
- ✅ **Basic Functionality**: 100% pass rate (20/20 tests)
- ✅ **Edge Cases**: 86% pass rate (37/43 tests)  
- ✅ **Dependency Resolution**: All tests passing
- ⚠️ **Concurrent Access**: Functional with performance notes for >50 parallel operations

## Troubleshooting

### Database Lock Timeout
If you get lock timeout errors, another process might be holding the lock:
```bash
# Check for lock file
ls -la .task-orchestrator/.lock

# If needed, remove stale lock (use with caution)
rm .task-orchestrator/.lock
```

### Database Corruption
If the database becomes corrupted:
```bash
# Export existing tasks
tm export --format json > backup.json

# Reinitialize
rm -rf .task-orchestrator
tm init

# Restore from backup (would need custom import script)
```

## Contributing

We welcome contributions! Please see our [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Quick Contributing Guide

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and test thoroughly
4. Ensure all tests pass: `./test_tm.sh && ./test_edge_cases.sh`
5. Submit a pull request

### Areas We Need Help With

- 🚀 Performance optimization for concurrent access
- 🐛 Fixing edge case test failures
- 📚 Documentation improvements
- 🌐 Additional export formats
- 🧪 More comprehensive test coverage

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with Python's standard library for maximum compatibility and zero dependencies
- Inspired by modern task management and DevOps orchestration tools
- Thanks to the open-source community for feedback and contributions

## Support

Get help and support through multiple channels:

### 📖 Documentation Resources

- **[USER_GUIDE.md](USER_GUIDE.md)** - Complete usage guide with tutorials and best practices
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues, solutions, and debugging help
- **[API_REFERENCE.md](API_REFERENCE.md)** - Complete technical reference
- **[docs/examples/](docs/examples/)** - Working code examples for common scenarios

### 🤝 Community Support

- 📋 **Issues**: [Report bugs or request features](https://github.com/T72/task-orchestrator/issues)
- 💬 **Discussions**: [Join the community discussion](https://github.com/T72/task-orchestrator/discussions)
- 🔖 **Releases**: [View changelog and releases](https://github.com/T72/task-orchestrator/releases)
- 📚 **Wiki**: [Community-contributed guides and tips](https://github.com/T72/task-orchestrator/wiki)

### 🚀 Quick Help

- **Getting started**: See [USER_GUIDE.md](USER_GUIDE.md#quick-start-5-minutes) for 5-minute setup
- **Common problems**: Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md#frequently-asked-questions-faq)
- **Integration help**: Review [claude_integration.py](docs/examples/claude_integration.py) for Claude Code setup
- **Performance issues**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#performance-issues) for optimization

---

**Made with ❤️ for developers and teams who value simplicity and reliability.**
