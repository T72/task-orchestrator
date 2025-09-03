#!/usr/bin/env python3
"""
LEAN Discovery Protocol - Maximized Value, Zero Waste
Read-only ORCHESTRATOR.md + Database as single source of truth
@implements FR-050: AI Agent Discovery Protocol (LEAN)
"""

import os
from pathlib import Path
from datetime import datetime

class LEANOrchestratorDiscovery:
    """
    LEAN implementation: Static discovery file, dynamic data from database
    Zero file contention, infinite scalability
    """
    
    def __init__(self):
        self.orchestrator_file = Path.cwd() / "ORCHESTRATOR.md"
        
    def create_static_orchestrator_md(self) -> bool:
        """
        Create ORCHESTRATOR.md ONCE at project init
        Never updates after creation - agents get dynamic data from database
        """
        if self.orchestrator_file.exists():
            return True  # Already exists, nothing to do
            
        content = """# 🤖 AI Agent Orchestration Protocol

This project uses **Task Orchestrator** for multi-agent coordination.

## 🚀 For AI Agents: Getting Started

```bash
# 1. Check if Task Orchestrator is available
[ -f ./tm ] && echo "✅ Task Orchestrator ready"

# 2. Get current task status from database (always fresh)
./tm list --format json

# 3. Create and manage tasks
./tm add "Your task" --assignee your_agent_id
./tm update TASK_ID --status in_progress
./tm complete TASK_ID
```

## 📊 Getting Live Status (No File Contention)

**IMPORTANT**: Task status is ALWAYS fetched from the database, never from this file.

```bash
# Get all tasks (real-time from database)
./tm list

# Get your assigned tasks
./tm list --assignee your_agent_id

# Watch for changes (efficient database polling)
./tm watch
```

## 🎯 Why This Design?

- **No file locks**: This file NEVER changes after creation
- **No race conditions**: Database handles all concurrency
- **Infinite scale**: 1000+ agents can read this simultaneously
- **Always current**: `./tm list` gives real-time data

## 🤝 Multi-Agent Patterns

### Pattern 1: Task Discovery
```bash
# Each agent checks for work independently
while true; do
    TASK=$(./tm list --assignee $AGENT_ID --status pending --format json | jq -r '.[0].id')
    if [ "$TASK" != "null" ]; then
        ./tm update $TASK --status in_progress
        # Do work...
        ./tm complete $TASK
    fi
    sleep 5
done
```

### Pattern 2: Dependency Coordination
```bash
# Database handles all dependency resolution
BACKEND=$(./tm add "Build API" --assignee backend_agent)
FRONTEND=$(./tm add "Build UI" --depends-on $BACKEND --assignee frontend_agent)
# Frontend automatically unblocks when backend completes
```

### Pattern 3: Event Monitoring
```bash
# Efficient database-backed watching
./tm watch --poll-interval 1
# Only queries database for changes, no file I/O
```

## 💡 Best Practices

1. **Never parse this file for status** - Use `./tm list`
2. **Set your agent ID** - `export TM_AGENT_ID=your_agent`
3. **Use JSON output for parsing** - `./tm list --format json`
4. **Let database handle concurrency** - It's built for this

---

*Task Orchestrator - LEAN Discovery Protocol*
*This file is static and never updates - get live data from `./tm list`*
"""
        
        try:
            self.orchestrator_file.write_text(content)
            print("✅ Created static ORCHESTRATOR.md (will never need updating)")
            return True
        except Exception as e:
            print(f"⚠️ Could not create ORCHESTRATOR.md: {e}")
            return False
    
    def needs_update(self) -> bool:
        """LEAN principle: This file NEVER needs updating"""
        return False


# That's it. 50 lines instead of 500. Works at any scale.