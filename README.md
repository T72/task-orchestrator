# Task Orchestrator

[![Version](https://img.shields.io/badge/version-2.6.0-blue.svg)](https://github.com/T72/task-orchestrator/releases)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Your AI agents are waiting for each other. Your developers are blocked. You're copying context between tasks.**

## This Changes Today

Task Orchestrator enables true parallel work. When one task completes, all dependent tasks instantly unblock. Context travels automatically. Each project stays isolated.

## 2-Minute Setup That Saves Hours

```bash
git clone https://github.com/T72/task-orchestrator.git
cd task-orchestrator
./tm init

# Watch the magic
BACKEND=$(./tm add "API endpoints" | grep -o '[a-f0-9]\{8\}')
FRONTEND=$(./tm add "React UI" --depends-on $BACKEND | grep -o '[a-f0-9]\{8\}')
TESTS=$(./tm add "Integration tests" --depends-on $BACKEND | grep -o '[a-f0-9]\{8\}')

# Backend completes → Frontend AND Tests unblock simultaneously
./tm complete $BACKEND
./tm list  # See both tasks ready!
```

## Why Teams Switch to Task Orchestrator

### 🚀 Instant Unblocking
No more "waiting for backend". Dependencies resolve automatically the moment upstream tasks complete.

### 🧠 Context That Travels
Stop copy-pasting requirements. Context, decisions, and discoveries stay with the task through every handoff.

### 🔒 True Project Isolation  
Work on 5 clients simultaneously. Each project's tasks stay in their own `.task-orchestrator/` directory.

### 🤖 Built for AI-First Teams
Multiple AI agents coordinate without conflicts. Private notes for reasoning. Shared context for results.

## The Killer Features

### 📋 Templates Save 30 Minutes Per Sprint
```bash
# Apply your sprint template in seconds
./tm template apply sprint.yaml --var sprint=5 --var feature="Payments"
# Creates 6 dependent tasks instantly
```

### 🎯 Interactive Wizard
```bash
./tm wizard         # Guided creation for complex workflows
./tm wizard --quick # Expert mode for power users
```

### 📊 Real-Time Progress
```bash
./tm watch          # Monitor all tasks live
./tm progress $ID "50% - API schema defined"
```

## See It Work (30 seconds each)

```bash
# Multi-agent coordination magic
bash docs/examples/multi-agent-workflow.sh

# True project isolation
bash docs/examples/project-isolation.sh

# Template time savings
bash docs/examples/template-workflow.sh
```

## Get Started

**Requirements**: Python 3.8+, Bash

```bash
git clone https://github.com/T72/task-orchestrator.git
cd task-orchestrator
./tm init
```

[Full Documentation](docs/guides/user-guide.md) | [Examples](docs/examples/) | [API Reference](docs/reference/api-reference.md)

## What Teams Are Saying

> "Cut our coordination overhead by 75%. AI agents work in parallel without stepping on each other."

> "Finally, true project isolation. Managing 8 client projects without confusion."

> "Templates alone save us 2 hours per sprint. The dependency resolution is magical."

---

**Ready to eliminate coordination overhead?** Start with the [2-minute quickstart](docs/guides/quickstart.md) or dive into [examples](docs/examples/).