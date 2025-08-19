# Role-Based Usage Protocol for Task Orchestrator

## Overview

The Task Orchestrator provides **two separate interfaces** for different agent roles:

1. **`orchestrate`** - For orchestrating agents who break down and assign work
2. **`worker`** - For specialist agents who receive and complete assignments

Each agent type uses ONLY their designated interface. This separation ensures clarity and prevents confusion.

## For Orchestrating Agents

### Your Tool: `orchestrate` (or `tm_orchestrator.py`)

### Your Responsibilities:
1. Receive complex tasks from users
2. Break them down into work items
3. Assign to appropriate specialists
4. Monitor progress
5. Coordinate between specialists

### Your Workflow:

```bash
# 1. Create a project for the user's request
orchestrate project "Build authentication system"
# Output: Project ID: proj_abc123

# 2. Break down into work items
orchestrate create proj_abc123 "Design database schema" \
  -r "Users table" "Sessions table" "Password reset tokens"

orchestrate create proj_abc123 "Implement JWT logic" \
  -r "Access tokens" "Refresh tokens" "Token validation"

orchestrate create proj_abc123 "Create REST endpoints" \
  -r "POST /auth/login" "POST /auth/logout" "POST /auth/refresh"

# 3. Assign work to specialists
orchestrate assign item_def456 database_specialist
orchestrate assign item_ghi789 backend_developer
orchestrate assign item_jkl012 api_developer

# 4. Monitor progress
orchestrate progress proj_abc123

# 5. Check discoveries
orchestrate discoveries proj_abc123

# 6. Complete project
orchestrate complete proj_abc123
```

### What You DON'T Do:
- Don't work on implementation details
- Don't use the worker interface
- Don't complete individual work items (specialists do that)

### The Handoff Package

When you assign work, a handoff package is automatically created:

```json
{
  "item_id": "item_def456",
  "assigned_to": "database_specialist",
  "task": {
    "title": "Design database schema",
    "requirements": ["Users table", "Sessions table"],
    "description": "Create normalized schema for auth system"
  },
  "project_context": {
    "project_title": "Build authentication system"
  }
}
```

This package is placed in `.task-orchestrator/handoffs/item_def456_handoff.json`

---

## For Specialist/Worker Agents

### Your Tool: `worker` (or `tm_worker.py`)

### Your Responsibilities:
1. Check for assigned work
2. Understand requirements
3. Execute the work
4. Report progress
5. Share important findings
6. Complete and deliver

### Your Workflow:

```bash
# Set your identity
export AGENT_ID="database_specialist"

# 1. Check what's assigned to you
worker check
# Output: You have 1 assigned work items:
#   - item_def456

# 2. Get the work details
worker get item_def456
# Output: 
# === Work Item: item_def456 ===
# Title: Design database schema
# Requirements:
#   - Users table
#   - Sessions table
#   - Password reset tokens

# 3. Start working and report progress
worker progress item_def456 "Analyzing requirements"
worker progress item_def456 "Designing normalized schema" --percent 50

# 4. Save your private notes (optional)
worker notes item_def456 "Considering UUID vs auto-increment for IDs"

# 5. Share important discoveries
worker discover item_def456 "Need to add email verification table" \
  --impact "Additional table required for email confirmation flow"

# 6. Handle blockers if they arise
worker blocker item_def456 "Need clarification on password requirements" \
  --needs "Min length, complexity rules"

# 7. Complete when done
worker complete item_def456 "Schema design complete with 4 tables"
```

### What You DON'T Do:
- Don't create new work items
- Don't assign work to others
- Don't use the orchestrator interface
- Don't worry about project structure

### What You Receive

Your handoff package tells you everything you need:
- Work item ID
- Clear requirements
- Project context
- Expected deliverables

You focus ONLY on your assigned work.

---

## Communication Flow

```
User Request
     ↓
Orchestrator
     ↓
Creates Work Items
     ↓
Assigns to Specialists → [Handoff Package]
                              ↓
                         Specialist
                              ↓
                    Checks Assignment (worker check)
                              ↓
                     Gets Details (worker get)
                              ↓
                        Works on Task
                              ↓
                   Reports Progress (worker progress)
                              ↓
                     Shares Findings (worker discover)
                              ↓
                      Completes Work (worker complete)
                              ↓
                         Orchestrator
                              ↓
                    Checks Progress (orchestrate progress)
                              ↓
                  Delivers to User (orchestrate complete)
```

---

## Example: Complete Workflow

### User Request
"Build a REST API for user management with authentication"

### Orchestrator Actions

```bash
# Orchestrator creates project
PROJECT=$(orchestrate project "User Management API")

# Break down work
DB_ITEM=$(orchestrate create $PROJECT "Database design")
AUTH_ITEM=$(orchestrate create $PROJECT "Authentication logic")
API_ITEM=$(orchestrate create $PROJECT "REST endpoints")

# Assign to specialists
orchestrate assign $DB_ITEM database_expert
orchestrate assign $AUTH_ITEM security_specialist
orchestrate assign $API_ITEM backend_developer
```

### Database Expert Actions

```bash
export AGENT_ID="database_expert"

# Check assignments
worker check
# Sees: item_db123

# Get details
worker get item_db123

# Work and update
worker progress item_db123 "Creating ERD diagram"
worker discover item_db123 "Need audit log table for compliance"
worker complete item_db123 "5 tables designed with constraints"
```

### Security Specialist Actions

```bash
export AGENT_ID="security_specialist"

# Check assignments
worker check
# Sees: item_auth456

# Get details
worker get item_auth456

# Work and update
worker progress item_auth456 "Implementing JWT with RS256"
worker discover item_auth456 "Rate limiting needed on auth endpoints"
worker complete item_auth456 "Secure auth with refresh tokens implemented"
```

### Orchestrator Monitors

```bash
# Check overall progress
orchestrate progress $PROJECT

# See all discoveries
orchestrate discoveries $PROJECT
# Sees: "Need audit log table", "Rate limiting needed"

# When all complete
orchestrate complete $PROJECT
```

---

## Key Benefits of This Separation

### For Orchestrators:
- Clear project overview
- Easy work assignment
- Progress visibility
- No implementation details to manage

### For Workers:
- Clear, focused assignments
- No project management overhead
- Simple progress reporting
- Just focus on execution

### For the System:
- No confusion about roles
- Clean separation of concerns
- Efficient communication
- Scalable to many agents

---

## Common Patterns

### Pattern 1: Parallel Work
Orchestrator assigns multiple items simultaneously:
```bash
orchestrate assign item1 agent1
orchestrate assign item2 agent2
orchestrate assign item3 agent3
# All work in parallel
```

### Pattern 2: Sequential Dependencies
Orchestrator waits for completion before next assignment:
```bash
# After database design completes
orchestrate assign api_implementation_item backend_dev
```

### Pattern 3: Specialist Discovers New Work
```bash
# Worker discovers issue
worker discover item123 "Need additional caching layer"

# Orchestrator sees discovery and creates new work
orchestrate discoveries project123
orchestrate create project123 "Implement caching layer"
orchestrate assign new_item cache_specialist
```

---

## File Structure

```
.task-orchestrator/
├── orchestration.db          # Orchestrator's database
├── handoffs/                  # Communication bridge
│   ├── item123_handoff.json  # Work assignment
│   ├── item123_progress.json # Progress reports
│   ├── item123_completion.json # Completion report
│   └── pending_agent1.txt    # Assignment notifications
└── workspace/                 # Worker's private space
    └── agent1/
        └── item123_notes.md   # Private working notes
```

---

## Installation

### For Orchestrators:
```bash
chmod +x tm_orchestrator.py
alias orchestrate="./tm_orchestrator.py"
```

### For Workers:
```bash
chmod +x tm_worker.py
alias worker="./tm_worker.py"
```

---

## Summary

**Orchestrators**: Use `orchestrate` to create, assign, and monitor work.

**Workers**: Use `worker` to receive, execute, and complete assignments.

**Never mix the interfaces** - each role has exactly the tools they need, nothing more.