# Getting Started with Task Orchestrator

Start orchestrating AI agents in under 5 minutes.

## Installation

### Quick Install
```bash
git clone https://github.com/T72/task-orchestrator.git
cd task-orchestrator
chmod +x tm
./tm init
```

### System Requirements
- Python 3.8+ (no dependencies!)
- Linux, macOS, or Windows (via WSL)
- 10MB disk space

## Your First Task

### Create a Simple Task
```bash
./tm add "Build authentication system"
# Output: Task created with ID: a1b2c3d4
```

### View Your Tasks
```bash
./tm list
```

### Update Task Status
```bash
./tm update a1b2c3d4 --status in_progress
./tm complete a1b2c3d4
```

## Dependency Management

Create tasks that depend on each other:

```bash
# Create parent task
BACKEND=$(./tm add "Build API" | grep -o '[a-f0-9]\{8\}')

# Create dependent task
FRONTEND=$(./tm add "Build UI" --depends-on $BACKEND | grep -o '[a-f0-9]\{8\}')

# View dependency chain
./tm list
```

## Multi-Agent Assignment

Assign tasks to specialized agents:

```bash
# Assign to backend specialist
./tm add "Create database schema" --assignee backend_agent

# Assign to frontend specialist
./tm add "Design user interface" --assignee frontend_agent

# View agent workload
./tm list --assignee backend_agent
```

## Commander's Intent Pattern

Use the WHY/WHAT/DONE pattern for clear communication:

```bash
./tm add "Implement auth" --context "WHY: Secure user data
                                    WHAT: Login, 2FA, sessions
                                    DONE: Users can login securely"
```

## Real-Time Monitoring

Watch for task updates:

```bash
# In terminal 1: Start monitoring
./tm watch

# In terminal 2: Make changes
./tm complete a1b2c3d4
# Terminal 1 shows: Task a1b2c3d4 completed!
```

## Next Steps

- **Learn core features**: Read the [Core Features Guide](core-features.md)
- **Advanced workflows**: See [Advanced Usage Guide](advanced-usage.md)
- **AI integration**: Check [AI Agent Integration](../reference/ai-agent-integration.md)
- **Troubleshooting**: Visit [Troubleshooting Guide](troubleshooting.md)

## Quick Reference

| Command | Description |
|---------|------------|
| `./tm init` | Initialize database |
| `./tm add "task"` | Create task |
| `./tm list` | View all tasks |
| `./tm show ID` | View task details |
| `./tm update ID --status STATUS` | Update status |
| `./tm complete ID` | Mark complete |
| `./tm watch` | Monitor changes |

---
*Getting started takes 5 minutes. Master orchestration in 30.*