# Task Orchestrator - Orchestrator Agent Guide

## Status: Guide
- **Guide**: Usage patterns and workflows for orchestrator agents
- **Note**: Some advanced features mentioned may be planned enhancements

## Last Updated: 2025-08-21
Version: 2.3.0

## 🎯 Purpose
This guide explains how to use Task Orchestrator to coordinate multiple specialized sub-agents working on complex projects. As an orchestrator, you'll learn to break down projects, assign tasks, and facilitate communication between specialists.

## 🚀 Quick Start for Orchestrators

```bash
# 1. Set your identity
export TM_AGENT_ID="orchestrator"

# 2. Create project structure
MAIN=$(tm add "Build authentication system" --priority high)
echo "Main task: $MAIN"

# Note: Dependencies use comma-separated list
DB=$(tm add "Design database" --depends-on $MAIN --assignee db_specialist)
API=$(tm add "Create API" --depends-on $DB --assignee backend_specialist)
UI=$(tm add "Build UI" --depends-on $API --assignee frontend_specialist)

# 3. Share project context
tm share $MAIN "Requirements: JWT auth, PostgreSQL, React"
tm share $MAIN "Timeline: 2 weeks, Priority: Critical"

# 4. Monitor progress
tm list --status in_progress
tm watch  # Real-time updates
```

## 📊 Task Delegation Patterns

### Pattern 1: Sequential Pipeline
Tasks flow from one specialist to another in order.

```bash
# Database → Backend → Frontend → QA
SCHEMA=$(tm add "Design schema" --assignee db_specialist)
API=$(tm add "Build API" --depends-on $SCHEMA --assignee backend_specialist)
UI=$(tm add "Create UI" --depends-on $API --assignee frontend_specialist)
TEST=$(tm add "Test system" --depends-on $UI --assignee qa_specialist)
```

### Pattern 2: Parallel Execution
Multiple specialists work simultaneously on independent tasks.

```bash
# Frontend and Backend work in parallel
FEATURE=$(tm add "User profile feature")

# These can run in parallel (same dependency)
tm add "API endpoints" --depends-on $FEATURE --assignee backend_specialist
tm add "UI components" --depends-on $FEATURE --assignee frontend_specialist
tm add "Database views" --depends-on $FEATURE --assignee db_specialist
```

### Pattern 3: Phased Delivery
Work organized in phases with checkpoints.

```bash
# Phase 1: Foundation
PHASE1=$(tm add "Phase 1: Core Infrastructure" --priority high)
tm add "Database setup" --depends-on $PHASE1 --assignee db_specialist
tm add "API framework" --depends-on $PHASE1 --assignee backend_specialist

# Phase 2: Features (blocked until Phase 1 completes)
PHASE2=$(tm add "Phase 2: Features" --depends-on $PHASE1)
tm add "User management" --depends-on $PHASE2 --assignee backend_specialist
tm add "Admin panel" --depends-on $PHASE2 --assignee frontend_specialist
```

## 💬 Communication Channels

### Understanding the Communication Channels

| Channel | Command | Visibility | Purpose |
|---------|---------|------------|---------|
| **Private Notes** | `tm note` | Agent only | Internal reasoning, research, thoughts |
| **Shared Updates** | `tm share` | All agents | Progress updates, decisions, handoffs |
| **Critical Discoveries** | `tm share --type discovery` | All agents | Critical findings, blockers |

### How Sub-Agents Communicate

```bash
# Sub-agent joins task
export TM_AGENT_ID="db_specialist"
tm join task_001

# Private reasoning (only this agent sees)
tm note task_001 "Considering NoSQL vs SQL for this use case"
tm note task_001 "Research: MongoDB might be better for nested data"

# Share progress (all agents see)
tm share task_001 "Decided on PostgreSQL with JSONB columns"
tm share task_001 "Schema draft complete, ready for review"

# Important discovery (alerts all agents)
tm share task_001 "CRITICAL: Need Redis for session management" --type discovery
```

## 🗂️ Information Architecture

```
~/.task-orchestrator/
├── tasks.db                    # Shared task database
├── shared_context/             # Team communication per task
│   └── task_*.yaml            # All agents' shared updates
├── private_notes/              # Private agent notes
│   └── agent_*/               # Per-agent directories
└── backups/                   # Database backups
```

## 📋 Orchestrator Workflows

### Workflow 1: Project Initialization

```bash
# 1. Create project root task
PROJECT=$(tm add "E-commerce Platform" --priority critical)

# 2. Define major components with dependencies
tm add "Database Design" --depends-on $PROJECT --assignee db_specialist
tm add "Payment Integration" --depends-on $PROJECT --assignee payment_specialist
tm add "Inventory System" --depends-on $PROJECT --assignee backend_specialist
tm add "Shopping Cart UI" --depends-on $PROJECT --assignee frontend_specialist

# 3. Set project context
tm share $PROJECT "Stack: Node.js, PostgreSQL, React, Stripe"
tm share $PROJECT "MVP Features: Products, Cart, Checkout, Orders"
tm share $PROJECT "Timeline: 6 weeks, Budget: 50k"

# 4. Create sync points
tm sync $PROJECT "Week 1: Database and API structure"
tm sync $PROJECT "Week 3: Integration testing"
tm sync $PROJECT "Week 5: User acceptance testing"
```

### Workflow 2: Task Assignment

```bash
# View all tasks and their assignees
tm list --assignee backend_specialist
tm list --status pending

# Assign based on expertise
tm add "OAuth implementation" --assignee security_specialist
tm add "Database optimization" --assignee db_specialist
tm add "UI responsiveness" --assignee frontend_specialist

# Reassign if needed
tm update task_123 --assignee senior_backend_specialist
```

### Workflow 3: Progress Monitoring

```bash
# Real-time monitoring
tm watch  # Shows updates as they happen

# Status overview
tm list --status in_progress
tm list --status blocked

# Specialist workload
tm list --assignee backend_specialist --status pending

# View completion metrics
tm metrics
```

### Workflow 4: Handling Blockers

```bash
# Sub-agent reports blocker
# backend_specialist: tm share task_005 "BLOCKED: Need database schema finalized"

# Orchestrator sees and responds
tm context task_005  # Review the blocker
tm share task_005 "Escalating to db_specialist for immediate resolution"
tm update task_001 --priority critical  # Increase priority of blocking task
```

## 🎯 Best Practices for Orchestrators

### 1. Clear Task Definitions
```bash
# Good: Specific and measurable
tm add "Create REST endpoints for user CRUD operations" --assignee backend_specialist

# Bad: Vague
tm add "Do backend stuff" --assignee backend_specialist
```

### 2. Proper Dependencies
```bash
# Set dependencies to prevent work on incomplete foundations
API=$(tm add "Create API endpoints")
tm add "Write API tests" --depends-on $API  # Can't test non-existent API
```

### 3. Context Sharing
```bash
# Share critical project information upfront
tm share $PROJECT "Design Decisions:"
tm share $PROJECT "- Authentication: JWT with refresh tokens"
tm share $PROJECT "- Database: PostgreSQL with read replicas"
tm share $PROJECT "- Caching: Redis for sessions"
```

### 4. Regular Synchronization
```bash
# Create regular sync points
tm sync $PROJECT "Daily standup 9am"
tm sync $PROJECT "Architecture review Thursday"
```

### 5. Progress Tracking
```bash
# Add progress updates to maintain visibility
tm progress task_001 "25% - Database schema drafted"
tm progress task_001 "50% - Tables created"
tm progress task_001 "75% - Migrations written"
tm progress task_001 "100% - Database ready"
```

## 🔄 Multi-Agent Coordination Patterns

### Pattern: Handoff Protocol
```bash
# Agent 1 completes their part
export TM_AGENT_ID="db_specialist"
tm share task_001 "Database schema complete. Tables created:"
tm share task_001 "- users, sessions, permissions"
tm share task_001 "Ready for backend implementation"
tm complete task_001

# Agent 2 picks up
export TM_AGENT_ID="backend_specialist"
tm join task_002
tm context task_001  # Review previous work
tm share task_002 "Starting API implementation based on schema"
```

### Pattern: Parallel Collaboration
```bash
# Multiple agents work on related tasks
FEATURE=$(tm add "User Dashboard Feature")

# Each specialist takes their part
tm add "Dashboard API" --depends-on $FEATURE --assignee backend_specialist
tm add "Dashboard UI" --depends-on $FEATURE --assignee frontend_specialist
tm add "Dashboard Analytics" --depends-on $FEATURE --assignee data_specialist

# Agents coordinate through shared context
tm share $FEATURE "API Contract: /api/dashboard/stats returns {visits, revenue, users}"
```

### Pattern: Review and Feedback
```bash
# Request review
tm share task_001 "Code complete, requesting review"
tm update task_001 --assignee senior_developer

# Reviewer provides feedback
export TM_AGENT_ID="senior_developer"
tm share task_001 "Review complete. Issues found:"
tm share task_001 "1. Missing error handling in auth"
tm share task_001 "2. SQL injection risk in search"
tm update task_001 --status blocked --assignee original_developer
```

## 🚨 Common Issues and Solutions

### Issue: Circular Dependencies
```bash
# Wrong: A depends on B, B depends on A
# Solution: Create a parent task both depend on
PARENT=$(tm add "Authentication Module")
tm add "Login API" --depends-on $PARENT
tm add "Login UI" --depends-on $PARENT
```

### Issue: Blocked Tasks
```bash
# Check what's blocking
tm list --status blocked
tm context $BLOCKED_TASK

# Escalate if needed
tm update $BLOCKING_TASK --priority critical
tm share $BLOCKING_TASK "URGENT: Blocking multiple downstream tasks"
```

### Issue: Lost Context
```bash
# Recover context from a task
tm context $TASK_ID  # See all shared updates
tm show $TASK_ID     # See task details
```

## 🎓 Advanced Orchestration

### Using Core Loop Features
```bash
# Set success criteria for measurable outcomes
tm add "Performance Optimization" \
  --criteria '[{"criterion":"Page load <2s","measurable":"true"}]' \
  --estimated-hours 20

# Track actual time spent
tm complete task_001 --actual-hours 18 --summary "Achieved 1.8s load time"

# Collect feedback for improvement
tm feedback task_001 --quality 5 --timeliness 4
```

### Generating Reports
```bash
# Export project status
tm export --format markdown > project_status.md

# Get metrics
tm metrics --period week
```

## 📚 Related Documentation

- [User Guide](./user-guide.md) - General Task Orchestrator usage
- [API Reference](../reference/api-reference.md) - Complete command reference
- [Claude Integration Guide](../reference/claude-integration-guide.md) - AI agent integration

---

*Note: This guide describes workflows and patterns. Some advanced features mentioned (like --tag) may be planned enhancements not yet implemented in v2.3.0.*