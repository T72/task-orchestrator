# Task Orchestrator

[![Version](https://img.shields.io/badge/version-2.6.0-blue.svg)](https://github.com/T72/task-orchestrator/releases)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Stop losing 30% of your time to coordination overhead.**

Task Orchestrator automatically unblocks dependencies, maintains context across your team, and keeps each project's tasks isolated.

## Quick Start (2 minutes)

```bash
# Clone and initialize
git clone https://github.com/T72/task-orchestrator.git
cd task-orchestrator
./tm init

# Create dependent tasks
BACKEND=$(./tm add "Build API" | grep -o '[a-f0-9]\{8\}')
./tm add "Build UI" --depends-on $BACKEND

# Complete backend → UI automatically unblocks
./tm complete $BACKEND
```

## Key Features

### 🔒 Project Isolation
Each project maintains its own `.task-orchestrator/` directory. No task confusion between projects.

### ⚡ Automatic Unblocking  
When task A completes, dependent tasks instantly unblock. No manual coordination.

### 📋 Context Persistence
Task context, files, and notes stay attached. Information travels where needed.

### 🤖 Multi-Agent Ready
AI agents and developers work in parallel without conflicts.

## What's New

### v2.6.0
- **Templates**: Reusable workflows with `tm template apply`
- **Wizard**: Interactive task creation with `tm wizard`  
- **Performance**: 2x faster operations

### v2.5.0
- **Project Isolation**: Each project gets its own database
- **Multi-Agent**: Improved coordination features

[See changelog →](CHANGELOG.md)

## See It In Action

Run these examples to experience the power:

```bash
# See multi-agent coordination
bash docs/examples/multi-agent-workflow.sh

# See project isolation  
bash docs/examples/project-isolation.sh

# See template time savings
bash docs/examples/template-workflow.sh

# See real-time progress tracking
bash docs/examples/real-time-updates.sh
```

## Documentation

### Reference
- [CLI Commands](docs/reference/cli-commands.md)
- [API Reference](docs/reference/api-reference.md)
- [Database Schema](docs/reference/database-schema.md)

### Guides  
- [Quick Start](docs/guides/quickstart.md)
- [User Guide](docs/guides/user-guide.md)
- [Examples](docs/examples/)

## Installation

**Requirements**: Python 3.8+, Unix-like OS

```bash
git clone https://github.com/T72/task-orchestrator.git
cd task-orchestrator
./tm init
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

MIT - see [LICENSE](LICENSE)

---

**Stop fighting coordination. Start shipping faster.**