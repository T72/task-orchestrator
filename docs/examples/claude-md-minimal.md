# Minimal Task Orchestrator Instructions for CLAUDE.md

Add this compact section to your CLAUDE.md if you want just the essentials:

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

### Multi-Agent Communication

```bash
export TM_AGENT_ID="claude"          # Set identity
./tm share <id> "Progress update"    # Share with team
./tm context <id>                    # View shared updates
```

### Auto-Approved Commands

Add to whitelisted commands: `./tm *`

---