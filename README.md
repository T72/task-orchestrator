# Task Orchestrator

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Tests](https://img.shields.io/badge/tests-passing-green.svg)](#testing)
[![Version](https://img.shields.io/badge/version-2.0.1--lean-blue.svg)](https://github.com/T72/task-orchestrator/releases)

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

**⚡ 2-Minute Setup:** See [INSTALL.md](INSTALL.md) for complete installation instructions.

```bash
git clone https://github.com/T72/task-orchestrator.git && cd task-orchestrator && chmod +x tm && ./tm init
```

## Quick Start

**🚀 2-Minute Guide:** [QUICKSTART.md](QUICKSTART.md) - Get productive immediately.

```bash
# Add task → Create dependencies → Track progress
./tm add "Deploy feature" --priority high
./tm list && ./tm update abc12345 --status in_progress
```

## Features

- **Cross-worktree synchronization**: Share tasks across all git worktrees
- **Dependency management**: Block tasks until dependencies complete
- **File references**: Track which files are associated with tasks
- **Notifications**: Get alerted when blocked tasks unblock or when your tasks are impacted
- **Unix-style CLI**: Simple, composable commands
- **Concurrent access**: Safe multi-agent access with file locking
- **Export capabilities**: JSON and Markdown export formats

## Usage

See [QUICKSTART.md](QUICKSTART.md) for immediate productivity or [docs/user-guide.md](docs/user-guide.md) for complete documentation.

### Essential Commands

```bash
./tm add "Task description" --priority high          # Create tasks
./tm add "Fix bug" --file src/auth.py:42            # Link to code
./tm add "Deploy" --depends-on abc12345             # Create dependencies
./tm list --status pending                          # Filter tasks
./tm update abc12345 --status in_progress           # Update status
./tm complete abc12345                              # Mark complete
```

### Key Features

- **Dependencies**: Tasks automatically unblock when dependencies complete
- **File Links**: Reference specific files and line numbers in code
- **Notifications**: Get alerted when blocked tasks become available
- **Export**: JSON/Markdown export for integration with other tools
- **Cross-platform**: Works on Linux, macOS, Windows

## Documentation

📚 **Complete Documentation:**
- [QUICKSTART.md](QUICKSTART.md) - 2-minute productivity guide
- [INSTALL.md](INSTALL.md) - Installation instructions
- [docs/user-guide.md](docs/user-guide.md) - Complete user manual
- [docs/reference/api-reference.md](docs/reference/api-reference.md) - API reference
- [docs/troubleshooting.md](docs/troubleshooting.md) - Common issues & solutions

## Examples

Working examples in `docs/examples/`:

```bash
python3 docs/examples/basic_usage.py              # Core functionality
python3 docs/examples/dependency_management.py    # Complex workflows  
python3 docs/examples/multi_agent_workflow.py     # Team coordination
python3 docs/examples/claude_integration.py       # AI integration
```

## Testing

```bash
./tests/test_tm.sh              # Basic functionality (100% pass rate)
./tests/test_edge_cases.sh      # Edge cases (86% pass rate)
./tests/stress_test.sh          # Performance testing
```

## Troubleshooting

**Common Issues:**
- Database locked: `rm .task-orchestrator/.lock` (if stale)
- Permission denied: `chmod +x tm`
- Not in git repo: `git init` first

See [docs/troubleshooting.md](docs/troubleshooting.md) for complete solutions.

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Quick start: Fork → Feature branch → Test → Pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- 📋 **Issues**: [GitHub Issues](https://github.com/T72/task-orchestrator/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/T72/task-orchestrator/discussions)  
- 📚 **Documentation**: [Complete guides](docs/)

---

**Made with ❤️ for developers who value simplicity and reliability.**
