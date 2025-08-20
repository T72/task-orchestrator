# Minimal Task Orchestrator Instructions for CLAUDE.md

**Copy everything between the horizontal lines below and paste it into your project's CLAUDE.md file:**

---

## Task Orchestrator

This project uses Task Orchestrator (`./tm`) for task management.

### Essential Commands

```bash
./tm init                                    # Initialize (once)
./tm add "Task description" --priority high  # Create task
./tm list                                    # View tasks
./tm update <id> --status in_progress       # Start work
./tm complete <id>                          # Mark done
./tm watch                                  # Check notifications
```

### Workflow

1. **Start work**: `./tm add "Feature name"` → Returns task ID
2. **Break down**: Create subtasks with `--depends-on <parent-id>`
3. **Track progress**: Update status as you work
4. **Complete**: Mark done to unblock dependencies

### MANDATORY: Multi-Agent Communication

**CRITICAL**: ALL agents MUST follow these protocols:

```bash
# 1. MANDATORY: Set unique agent identity
export TM_AGENT_ID="[role]_[specialty]_[session]"

# 2. MANDATORY: Use all three channels appropriately
./tm share <id> "PUBLIC: Task completed, API endpoints ready"     # Shared coordination
./tm note <id> "PRIVATE: Evaluating approach A vs B internally"   # Internal reasoning  
./tm discover <id> "CRITICAL: Security issue affects all agents"  # Broadcast alerts

# 3. MANDATORY: Check context before starting work
./tm context <id>                    # Review shared updates from other agents

# 4. MANDATORY: Acknowledge task assignments within 5 minutes
./tm share <id> "ACKNOWLEDGED: Starting work. ETA 2 hours."
```

**Response Times (MANDATORY)**:
- Acknowledge tasks: 5 minutes
- Progress updates: Every 30 minutes  
- Critical alerts: 2 minutes response

### Auto-Approved Commands

Add to whitelisted commands: `./tm *`

---