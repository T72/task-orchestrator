# Task Orchestrator User Guide

**Stop losing 30% of your time to coordination overhead.**

## Quick Start (2 Minutes)

```bash
# Install
git clone https://github.com/T72/task-orchestrator.git
cd task-orchestrator
./tm init

# Create dependent tasks
BACKEND=$(./tm add "Build API" | grep -o '[a-f0-9]\{8\}')
FRONTEND=$(./tm add "Build UI" --depends-on $BACKEND | grep -o '[a-f0-9]\{8\}')

# Complete backend → Frontend automatically unblocks
./tm complete $BACKEND
./tm list
```

## Multi-Agent Orchestration (The Killer Feature)

### Setup Agents

```bash
# Each agent sets identity
export TM_AGENT_ID="orchestrator"     # Agent 1
export TM_AGENT_ID="backend_dev"      # Agent 2  
export TM_AGENT_ID="frontend_dev"     # Agent 3
```

### Orchestrator Creates Work

```bash
# Create project structure with dependencies
DB=$(./tm add "Database schema" | grep -o '[a-f0-9]\{8\}')
API=$(./tm add "API endpoints" --depends-on $DB | grep -o '[a-f0-9]\{8\}')
UI=$(./tm add "User interface" --depends-on $API | grep -o '[a-f0-9]\{8\}')

# Share context all agents need
./tm share $DB "PostgreSQL, 3 tables needed"
```

### Agents Work in Parallel

```bash
# DB specialist works
export TM_AGENT_ID="db_specialist"
./tm progress $DB "50% - Tables created"
./tm complete $DB

# Backend automatically starts (was blocked, now unblocked!)
export TM_AGENT_ID="backend_dev"
./tm progress $API "Building endpoints..."
```

### Key Commands for Coordination

```bash
./tm share [id] "message"    # Share with all agents
./tm note [id] "private"     # Private notes
./tm context [id]            # View all context
./tm watch                   # Monitor real-time
./tm progress [id] "update"  # Show progress
```

## Core Features

### 1. Automatic Dependency Resolution

When task A completes, dependent task B automatically unblocks. No manual coordination.

```bash
./tm add "Deploy" --depends-on $TESTS --depends-on $SECURITY
# Deploy waits for both
./tm complete $TESTS     # Deploy still blocked
./tm complete $SECURITY  # Deploy now ready!
```

### 2. Project Isolation

Each project gets its own `.task-orchestrator/` directory:

```bash
cd project-a && ./tm init  # project-a/.task-orchestrator/
cd project-b && ./tm init  # project-b/.task-orchestrator/
# Tasks never mix!
```

### 3. Task Templates (Save 30+ Minutes)

```yaml
# sprint.yaml
name: sprint
tasks:
  - title: "Planning {{sprint}}"
  - title: "Dev {{feature}}"
    depends_on: [0]
  - title: "Test {{feature}}"
    depends_on: [1]
```

```bash
./tm template apply sprint.yaml --var sprint=1 --var feature="Auth"
# Creates all 3 tasks in seconds
```

### 4. Interactive Wizard

```bash
./tm wizard          # Guided creation
./tm wizard --quick  # Expert mode
```

## Essential Commands

### Task Management
```bash
./tm add "Task title" [options]      # Create task
./tm list [--status STATE]           # List tasks
./tm show [task_id]                  # Task details
./tm update [id] --status STATE      # Update status
./tm complete [id]                   # Mark complete
./tm delete [id]                     # Delete task
```

### Options
```bash
--priority critical|high|medium|low  # Set priority
--depends-on [id]                    # Add dependency
--assignee [name]                    # Assign to someone
--file path/to/file.py:45            # Link to code
```

### Status Values
- `pending` - Not started
- `in_progress` - Being worked on
- `blocked` - Waiting for dependency
- `completed` - Done

## Common Workflows

### Sprint Planning
```bash
# Create sprint with all tasks
./tm template apply sprint.yaml --var sprint=5 --var feature="Payments"
```

### Bug Fix
```bash
BUG=$(./tm add "Critical: Login broken" -p critical | grep -o '[a-f0-9]\{8\}')
./tm update $BUG --status in_progress
./tm progress $BUG "Found issue in auth.py:45"
./tm complete $BUG
```

### Feature Development
```bash
# Backend creates feature
FEATURE=$(./tm add "User profiles" | grep -o '[a-f0-9]\{8\}')

# Frontend depends on it
UI=$(./tm add "Profile UI" --depends-on $FEATURE | grep -o '[a-f0-9]\{8\}')

# Complete backend → UI unblocks
./tm complete $FEATURE
```

## Configuration

### Database Location
```bash
# Default: Project-local
./.task-orchestrator/tasks.db

# Override to global
export TM_DB_PATH=~/.task-orchestrator
```

### Agent Identity
```bash
export TM_AGENT_ID="your_name"
```

## Troubleshooting

### Database Locked
```bash
rm .task-orchestrator/.lock
```

### Can't Find tm
```bash
chmod +x tm
./tm init
```

### Tasks Not Unblocking
```bash
# Check dependencies
./tm show [task_id]
# Look for "Blocked by:" section
```

---

**Need more?** See [examples](../examples/) or [API reference](../reference/api-reference.md)