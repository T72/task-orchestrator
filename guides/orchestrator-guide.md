# Task Orchestrator - Orchestrator Agent Guide

## 🎯 Purpose
This guide explains how to use Task Orchestrator to coordinate multiple specialized sub-agents working on complex projects. As an orchestrator, you'll learn to break down projects, assign tasks, and facilitate communication between specialists.

## 🚀 Quick Start for Orchestrators

```bash
# 1. Set your identity
export TM_AGENT_ID="orchestrator"

# 2. Create project structure
MAIN=$(./tm add "Build authentication system" -p high)
DB=$(./tm add "Design database" --depends-on $MAIN --assignee db_specialist)
API=$(./tm add "Create API" --depends-on $DB --assignee backend_specialist)
UI=$(./tm add "Build UI" --depends-on $API --assignee frontend_specialist)

# 3. Share project context
./tm share $MAIN "Requirements: JWT auth, PostgreSQL, React"
./tm share $MAIN "Timeline: 2 weeks, Priority: Critical"

# 4. Monitor progress
./tm list --status in_progress
./tm watch  # Real-time updates
```

## 📊 Task Delegation Patterns

### Pattern 1: Sequential Pipeline
Tasks flow from one specialist to another in order.

```bash
# Database → Backend → Frontend → QA
SCHEMA=$(./tm add "Design schema" --assignee db_specialist)
API=$(./tm add "Build API" --depends-on $SCHEMA --assignee backend_specialist)
UI=$(./tm add "Create UI" --depends-on $API --assignee frontend_specialist)
TEST=$(./tm add "Test system" --depends-on $UI --assignee qa_specialist)
```

### Pattern 2: Parallel Execution
Multiple specialists work simultaneously on independent tasks.

```bash
# Frontend and Backend work in parallel
FEATURE=$(./tm add "User profile feature")
./tm add "API endpoints" --depends-on $FEATURE --assignee backend_specialist
./tm add "UI components" --depends-on $FEATURE --assignee frontend_specialist
./tm add "Database views" --depends-on $FEATURE --assignee db_specialist
```

### Pattern 3: Phased Delivery
Work organized in phases with checkpoints.

```bash
# Phase 1: Foundation
PHASE1=$(./tm add "Phase 1: Core Infrastructure" -p high)
./tm add "Database setup" --depends-on $PHASE1 --assignee db_specialist --tag phase1
./tm add "API framework" --depends-on $PHASE1 --assignee backend_specialist --tag phase1

# Phase 2: Features (blocked until Phase 1 completes)
PHASE2=$(./tm add "Phase 2: Features" --depends-on $PHASE1)
./tm add "User management" --depends-on $PHASE2 --assignee backend_specialist --tag phase2
./tm add "Admin panel" --depends-on $PHASE2 --assignee frontend_specialist --tag phase2
```

## 💬 Communication Channels

### Understanding the Three Channels

| Channel | Command | Visibility | Purpose |
|---------|---------|------------|---------|
| **Private Notes** | `tm note` | Agent only | Internal reasoning, research, thoughts |
| **Shared Updates** | `tm share` | All agents | Progress updates, decisions, handoffs |
| **Discoveries** | `tm discover` | All agents | Critical findings, blockers, breakthroughs |

### How Sub-Agents Communicate

```bash
# Sub-agent joins task
export TM_AGENT_ID="db_specialist"
./tm join task_001

# Private reasoning (only this agent sees)
./tm note task_001 "Considering NoSQL vs SQL for this use case"
./tm note task_001 "Research: MongoDB might be better for nested data"

# Share progress (all agents see)
./tm share task_001 "Decided on PostgreSQL with JSONB columns"
./tm share task_001 "Schema draft complete, ready for review"

# Important discovery (alerts all agents)
./tm discover task_001 "CRITICAL: Need Redis for session management"
```

## 🗂️ Information Architecture

```
.task-orchestrator/
├── tasks.db                    # Shared task database
├── contexts/                    # Team communication per task
│   ├── context_task001_*.md    # All agents' shared updates
│   └── context_task002_*.md    
├── notes/                       # Private agent notes
│   ├── notes_task001_db_specialist.md      # Private to db_specialist
│   └── notes_task001_backend_specialist.md  # Private to backend_specialist
└── archives/                    # Completed task history
```

## 📋 Orchestrator Workflows

### Workflow 1: Project Initialization

```bash
# 1. Create project hierarchy
PROJECT=$(./tm add "E-commerce Platform" -p critical)

# 2. Define major components
./tm add "Database Design" --depends-on $PROJECT --assignee db_specialist
./tm add "Payment Integration" --depends-on $PROJECT --assignee payment_specialist
./tm add "Inventory System" --depends-on $PROJECT --assignee backend_specialist
./tm add "Shopping Cart UI" --depends-on $PROJECT --assignee frontend_specialist

# 3. Set project context
./tm share $PROJECT "Stack: Node.js, PostgreSQL, React, Stripe"
./tm share $PROJECT "MVP Features: Products, Cart, Checkout, Orders"
./tm share $PROJECT "Timeline: 6 weeks, Budget: $50k"

# 4. Create sync points
./tm sync $PROJECT "Week 1: Database and API structure"
./tm sync $PROJECT "Week 3: Integration testing"
./tm sync $PROJECT "Week 5: User acceptance testing"
```

### Workflow 2: Task Assignment

```bash
# View available specialists
./tm list --group-by assignee

# Assign based on expertise
./tm add "OAuth implementation" --assignee security_specialist --tag auth
./tm add "Database optimization" --assignee db_specialist --tag performance
./tm add "UI responsiveness" --assignee frontend_specialist --tag mobile

# Reassign if needed
./tm update task_123 --assignee senior_backend_specialist
```

### Workflow 3: Progress Monitoring

```bash
# Real-time monitoring
./tm watch  # Shows updates as they happen

# Status overview
./tm list --status in_progress
./tm list --status blocked

# Specialist workload
./tm list --assignee backend_specialist --status pending

# Phase tracking
./tm list --tag phase1 --status completed
```

### Workflow 4: Handling Blockers

```bash
# Sub-agent reports blocker
# backend_specialist: ./tm discover task_005 "BLOCKED: Need database schema finalized"

# Orchestrator sees and responds
./tm context task_005  # Review the blocker
./tm share task_005 "Escalating to db_specialist for immediate resolution"
./tm update task_001 --priority critical  # Increase priority of blocking task
```

## 🎯 Best Practices for Orchestrators

### 1. Clear Task Definitions
```bash
# Good: Specific and measurable
./tm add "Create REST endpoints for user CRUD operations" --assignee backend_specialist

# Bad: Vague
./tm add "Do backend stuff" --assignee backend_specialist
```

### 2. Proper Dependencies
```bash
# Set dependencies to prevent work on incomplete foundations
API=$(./tm add "Create API endpoints")
./tm add "Write API tests" --depends-on $API  # Can't test non-existent API
```

### 3. Context Sharing
```bash
# Share critical project information upfront
./tm share $PROJECT "Design Decisions:"
./tm share $PROJECT "- Use JWT for auth (not sessions)"
./tm share $PROJECT "- PostgreSQL for main data, Redis for cache"
./tm share $PROJECT "- React with TypeScript for frontend"
```

### 4. Regular Sync Points
```bash
# Create checkpoints for team synchronization
./tm sync $PROJECT "SYNC: All teams check in at 2 PM"
./tm sync $PROJECT "MILESTONE: Phase 1 complete, beginning integration"
```

### 5. Monitor and Respond
```bash
# Set up monitoring routine
while true; do
    ./tm list --status blocked
    ./tm watch  # Check for discoveries
    sleep 300  # Check every 5 minutes
done
```

## 🔄 Complete Example: Authentication System

Here's a full orchestration example:

```bash
#!/bin/bash
# orchestrate_auth.sh - Complete authentication system orchestration

# Setup
export TM_AGENT_ID="orchestrator"

# 1. Create main project
echo "Creating authentication system project..."
AUTH=$(./tm add "Implement secure authentication system" -p critical)

# 2. Share requirements
./tm share $AUTH "Requirements Document:"
./tm share $AUTH "- JWT-based authentication"
./tm share $AUTH "- Password reset via email"
./tm share $AUTH "- 2FA support (TOTP)"
./tm share $AUTH "- Session management with Redis"
./tm share $AUTH "- GDPR compliant audit logs"

# 3. Create phase 1: Database
echo "Phase 1: Database Design"
PHASE1=$(./tm add "Phase 1: Database Schema" --depends-on $AUTH)

DB_USERS=$(./tm add "Design users table" \
    --depends-on $PHASE1 \
    --assignee db_specialist \
    --tag phase1)

DB_SESSIONS=$(./tm add "Design sessions table" \
    --depends-on $PHASE1 \
    --assignee db_specialist \
    --tag phase1)

DB_AUDIT=$(./tm add "Design audit log table" \
    --depends-on $PHASE1 \
    --assignee db_specialist \
    --tag phase1)

# 4. Create phase 2: Backend
echo "Phase 2: Backend Implementation"
PHASE2=$(./tm add "Phase 2: API Development" --depends-on $PHASE1)

API_JWT=$(./tm add "Implement JWT generation/validation" \
    --depends-on $PHASE2 \
    --assignee backend_specialist \
    --tag phase2)

API_ENDPOINTS=$(./tm add "Create auth REST endpoints" \
    --depends-on $PHASE2 \
    --assignee backend_specialist \
    --tag phase2)

API_MIDDLEWARE=$(./tm add "Build authentication middleware" \
    --depends-on $API_JWT \
    --assignee backend_specialist \
    --tag phase2)

API_2FA=$(./tm add "Implement 2FA with TOTP" \
    --depends-on $API_ENDPOINTS \
    --assignee security_specialist \
    --tag phase2)

# 5. Create phase 3: Frontend
echo "Phase 3: User Interface"
PHASE3=$(./tm add "Phase 3: Frontend Development" --depends-on $PHASE2)

UI_LOGIN=$(./tm add "Build login component" \
    --depends-on $PHASE3 \
    --assignee frontend_specialist \
    --tag phase3)

UI_REGISTER=$(./tm add "Build registration flow" \
    --depends-on $PHASE3 \
    --assignee frontend_specialist \
    --tag phase3)

UI_RESET=$(./tm add "Build password reset UI" \
    --depends-on $PHASE3 \
    --assignee frontend_specialist \
    --tag phase3)

UI_2FA=$(./tm add "Build 2FA setup interface" \
    --depends-on $PHASE3 \
    --assignee frontend_specialist \
    --tag phase3)

# 6. Create phase 4: Testing
echo "Phase 4: Testing & Security"
PHASE4=$(./tm add "Phase 4: Testing" --depends-on $PHASE3)

TEST_UNIT=$(./tm add "Write unit tests" \
    --depends-on $PHASE4 \
    --assignee qa_specialist \
    --tag phase4)

TEST_INTEGRATION=$(./tm add "Write integration tests" \
    --depends-on $PHASE4 \
    --assignee qa_specialist \
    --tag phase4)

TEST_SECURITY=$(./tm add "Perform security audit" \
    --depends-on $PHASE4 \
    --assignee security_specialist \
    --tag phase4)

# 7. Set milestones
./tm sync $AUTH "Milestone 1: Database complete (Day 3)"
./tm sync $AUTH "Milestone 2: API complete (Day 7)"
./tm sync $AUTH "Milestone 3: UI complete (Day 10)"
./tm sync $AUTH "Milestone 4: Testing complete (Day 14)"

# 8. Final message
echo "Orchestration complete!"
echo "Total tasks created: $(./tm list | wc -l)"
echo ""
echo "Specialists can now run:"
echo "  export TM_AGENT_ID=<specialist_name>"
echo "  ./tm list --assignee <specialist_name> --status pending"
echo ""
echo "Monitor progress with:"
echo "  ./tm list --tag phase1"
echo "  ./tm watch"
```

## 📊 Monitoring Dashboard

Create a simple monitoring script:

```bash
#!/bin/bash
# monitor.sh - Orchestrator's monitoring dashboard

while true; do
    clear
    echo "=== Task Orchestrator Dashboard ==="
    echo "Time: $(date)"
    echo ""
    
    echo "📊 Overview:"
    echo "  Total tasks: $(./tm list | wc -l)"
    echo "  Pending: $(./tm list --status pending | wc -l)"
    echo "  In Progress: $(./tm list --status in_progress | wc -l)"
    echo "  Blocked: $(./tm list --status blocked | wc -l)"
    echo "  Completed: $(./tm list --status completed | wc -l)"
    echo ""
    
    echo "👥 Specialist Workload:"
    for specialist in db_specialist backend_specialist frontend_specialist qa_specialist; do
        count=$(./tm list --assignee $specialist --status in_progress | wc -l)
        echo "  $specialist: $count active tasks"
    done
    echo ""
    
    echo "🚨 Blocked Tasks:"
    ./tm list --status blocked --format simple | head -5
    echo ""
    
    echo "📝 Recent Updates:"
    ./tm list --status in_progress --format simple | head -5
    echo ""
    
    echo "Refreshing in 30 seconds... (Ctrl+C to exit)"
    sleep 30
done
```

## 🎓 Advanced Orchestration Techniques

### Dynamic Task Creation
```bash
# Create tasks based on discovered requirements
./tm discover $PROJECT "Found 5 API endpoints needed"
for endpoint in users posts comments likes shares; do
    ./tm add "Create $endpoint endpoint" --assignee backend_specialist
done
```

### Conditional Dependencies
```bash
# Create fallback tasks
PRIMARY=$(./tm add "Try approach A" --assignee specialist_1)
FALLBACK=$(./tm add "Fallback to approach B" --assignee specialist_2)
./tm update $FALLBACK --status blocked  # Manually manage based on PRIMARY outcome
```

### Resource Balancing
```bash
# Check specialist availability before assignment
for specialist in $(./tm list --group-by assignee | grep specialist); do
    workload=$(./tm list --assignee $specialist --status in_progress | wc -l)
    if [ $workload -lt 3 ]; then
        ./tm add "New task" --assignee $specialist
        break
    fi
done
```

## 🚀 Quick Reference Card

```bash
# Essential Orchestrator Commands
./tm add "Task" --depends-on $PARENT --assignee specialist  # Create and assign
./tm share $TASK "Context for all agents"                   # Share information
./tm sync $TASK "Synchronization point"                     # Create checkpoint
./tm list --status blocked                                  # Find blockers
./tm list --assignee specialist --status pending            # Check workload
./tm watch                                                  # Real-time monitoring
./tm context $TASK                                         # Review all updates

# Task States
pending → in_progress → completed
         ↓
       blocked → cancelled

# Communication Types
note: Private to agent
share: Visible to all
discover: Alert to all
sync: Checkpoint for all
```

## 📚 Further Reading

- [Multi-Agent Workflow Examples](../examples/multi_agent_workflow.py)
- [Dependency Management](../examples/dependency_management.py)
- [API Reference](../reference/api-reference.md)
- [Troubleshooting Guide](troubleshooting.md)

---

**Remember**: As an orchestrator, your role is to structure work, facilitate communication, and remove blockers. Let the specialists focus on their expertise while you maintain the big picture.