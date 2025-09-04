# Task Orchestrator User Guide

Welcome to Task Orchestrator - the tool that transforms meta-agents into orchestration engines.

## 📚 Documentation Structure

### Quick Navigation

| Guide | Purpose | Time to Read |
|-------|---------|--------------|
| **[Getting Started](getting-started.md)** | Installation and first tasks | 5 minutes |
| **[Core Features](core-features.md)** | Essential capabilities | 15 minutes |
| **[Advanced Usage](advanced-usage.md)** | Complex workflows | 20 minutes |

### By User Type

#### 🚀 New Users
1. Start with **[Getting Started](getting-started.md)**
2. Learn **[Core Features](core-features.md)**
3. Try the **[QuickStart Guide](quickstart-claude-code.md)**

#### 👨‍💻 Developers
1. Review **[Core Features](core-features.md)**
2. Master **[Advanced Usage](advanced-usage.md)**
3. Read **[Developer Guide](developer-guide.md)**
4. Check **[API Reference](../reference/api-reference.md)**

#### 🤖 AI Agent Builders
1. Read **[AI Agent Integration](../reference/ai-agent-integration.md)**
2. Study **[Orchestrator Guide](orchestrator-guide.md)**
3. Implement **[Task Delegation Framework](task-delegation-framework.md)**

#### 🔧 System Administrators
1. Follow **[Deployment Guide](task-orchestrator-deployment-guide.md)**
2. Configure using **[Advanced Usage](advanced-usage.md#advanced-configuration)**
3. Monitor with **[Troubleshooting Guide](troubleshooting.md)**

## Key Concepts

### What is Task Orchestrator?
Task Orchestrator is a lightweight, zero-dependency tool that enables AI agents to coordinate complex workflows with:
- **95%+ completion rates** through intelligent dependency management
- **4-5x speed improvements** via parallel execution
- **<5% rework** using Commander's Intent framework

### Core Principles
1. **Commander's Intent**: Every task has WHY/WHAT/DONE
2. **Shared Context**: Agents share discoveries and insights
3. **Automatic Unblocking**: Dependencies resolve instantly
4. **Real-Time Awareness**: Watch mode enables immediate reactions

## Feature Overview

### Essential Features
- ✅ Task creation and management
- ✅ Dependency chains and resolution
- ✅ Multi-agent assignment
- ✅ Progress tracking
- ✅ Real-time notifications

### Advanced Capabilities
- ✅ Template system
- ✅ Bulk operations
- ✅ Custom workflows
- ✅ Performance analytics
- ✅ CI/CD integration

### Enterprise Features
- ✅ Orchestration enforcement
- ✅ Configurable policies
- ✅ Audit trails
- ✅ Team metrics
- ✅ Custom reporting

## Learning Path

### Week 1: Fundamentals
- Day 1-2: **[Getting Started](getting-started.md)**
- Day 3-4: **[Core Features](core-features.md)** (sections 1-3)
- Day 5: **[Core Features](core-features.md)** (sections 4-6)

### Week 2: Advanced Skills
- Day 1-2: **[Advanced Usage](advanced-usage.md)** (templates & bulk ops)
- Day 3-4: **[Advanced Usage](advanced-usage.md)** (workflows & integration)
- Day 5: **[AI Agent Integration](../reference/ai-agent-integration.md)**

### Week 3: Mastery
- Day 1-2: Custom automation scripts
- Day 3-4: Performance optimization
- Day 5: Team rollout and training

## Support Resources

### Documentation
- **Guides**: Step-by-step instructions
- **Reference**: Technical specifications
- **Examples**: Real-world scenarios
- **Troubleshooting**: Common issues and solutions

### Getting Help
- **Quick Help**: Run `./tm --help`
- **Command Help**: Run `./tm COMMAND --help`
- **Troubleshooting**: See [Troubleshooting Guide](troubleshooting.md)
- **Issues**: Report via `docs/support/templates/issue.md`
- **Features**: Request via `docs/support/templates/feedback.md`

## Version Information
- **Current Version**: 2.7.2
- **Released**: September 3, 2025
- **Highlights**: 91.5% requirements coverage, enforcement system
- **Migration**: See [Migration Guide](../reference/migration-guide.md)

## Quick Reference Card

### Most Used Commands
```bash
./tm init                    # Initialize
./tm add "task"             # Create task
./tm list                   # View tasks
./tm show ID                # Task details
./tm update ID --status X   # Update status
./tm complete ID            # Mark complete
./tm watch                  # Monitor changes
```

### Power User Commands
```bash
./tm add "task" --context "WHY: X WHAT: Y DONE: Z"  # Commander's Intent
./tm add "task" --depends-on ID                     # Dependencies
./tm add "task" --assignee agent                    # Assignment
./tm share ID "message"                             # Share context
./tm critical-path                                  # Find bottlenecks
./tm metrics --completion-rate                      # Analytics
```

## Philosophy

Task Orchestrator follows these principles:
- **LEAN**: Eliminate waste, maximize value
- **KISS**: Keep it simple and straightforward
- **Zero Dependencies**: Python stdlib only
- **Local First**: Your data stays on your machine
- **Tool Agnostic**: Works with any AI system

## Community

- **GitHub**: [T72/task-orchestrator](https://github.com/T72/task-orchestrator)
- **License**: MIT
- **Contributing**: See [CONTRIBUTING.md](../../CONTRIBUTING.md)

---

*Choose your path: [Get Started](getting-started.md) | [Learn Features](core-features.md) | [Go Advanced](advanced-usage.md)*