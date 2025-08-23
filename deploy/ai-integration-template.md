# AI Integration Template - Task Orchestrator

**Template for AI agent coordination in your projects**

---

# Multi-Agent Orchestration Instructions

## 🔒 PROTECTED SECTION - TASK ORCHESTRATOR INTEGRATION

**⚠️ CRITICAL: This project uses Task Orchestrator for multi-agent coordination**

### Task Orchestrator Integration Requirements

All AI agents working in this project MUST use Task Orchestrator for coordination:

1. **Before starting any work** - Check for existing tasks:
   ```bash
   ./tm list --status pending --status in_progress
   ```

2. **For all user requests** - Create appropriate tasks:
   ```bash
   # Create epic for large requests
   ./tm add "User Request: [brief description]" -p high
   
   # Create subtasks with dependencies
   ./tm add "Implement [feature]" --depends-on [parent_id] --file path/to/file.py
   ```

3. **Always join tasks** before working:
   ```bash
   ./tm join [task_id]
   ```

4. **Share progress** regularly:
   ```bash
   ./tm share [task_id] "Progress update: [what you accomplished]"
   ```

5. **Use file references** for code-related tasks:
   ```bash
   ./tm add "Fix bug in auth" --file src/auth/login.py:45:67
   ```

6. **For critical discoveries**:
   ```bash
   ./tm discover [task_id] "IMPORTANT: [critical finding or blocker]"
   ```

7. **Check notifications** before starting work:
   ```bash
   ./tm watch
   ```

8. **View context** when joining existing work:
   ```bash
   ./tm context [task_id]
   ```

9. **Complete with impact review** for significant changes:
   ```bash
   ./tm complete [task_id] --impact-review
   ```

### Multi-Agent Coordination Protocol

#### Agent Identity
Set your agent identity:
```bash
export TM_AGENT_ID="claude_[specialty]_[timestamp]"
# Examples: claude_backend_001, claude_frontend_002, claude_general_003
```

#### Work Assignment Protocol
1. **Check dependencies** - Don't start blocked tasks
2. **Communicate intent** - Share what you're planning
3. **Coordinate changes** - Use sync points for major milestones
4. **Share discoveries** - Broadcast important findings
5. **Respect ownership** - Don't override others' active work

#### Collaboration Commands Reference
```bash
# Essential coordination commands
./tm join [task_id]              # Join task collaboration
./tm share [task_id] "message"   # Share with all agents
./tm note [task_id] "note"       # Private note (only you see)
./tm discover [task_id] "alert"  # Broadcast critical finding
./tm sync [task_id] "milestone"  # Create sync point
./tm context [task_id]           # View shared context
./tm watch                       # Check notifications
```

### Example Multi-Agent Workflow

```bash
# Human Request: "Add user authentication to our app"

# Agent 1 - Creates epic and architecture
export TM_AGENT_ID="claude_architect"
EPIC=$(./tm add "User Authentication Feature" -p high | grep -o '[a-f0-9]\{8\}')
DB_TASK=$(./tm add "Design auth database schema" --depends-on $EPIC)
API_TASK=$(./tm add "Implement auth API" --depends-on $DB_TASK)
UI_TASK=$(./tm add "Build login UI" --depends-on $API_TASK)

./tm join $EPIC
./tm share $EPIC "Architecture: Using JWT tokens, PostgreSQL for users table"

# Agent 2 - Database specialist (different session)
export TM_AGENT_ID="claude_database"
./tm join $DB_TASK
./tm context $DB_TASK  # Sees architecture decisions
./tm share $DB_TASK "Starting database schema design"

# Work on database schema...
./tm complete $DB_TASK --impact-review
./tm share $DB_TASK "Database schema complete - see migrations/001_auth.sql"

# Agent 3 - Backend specialist (different session)  
export TM_AGENT_ID="claude_backend"
# DB task completion automatically unblocks API task
./tm join $API_TASK
./tm context $API_TASK  # Sees all previous context
./tm share $API_TASK "Implementing JWT authentication endpoints"

# Work on API...
./tm discover $API_TASK "SECURITY: Need rate limiting on login endpoint"
./tm sync $API_TASK "API endpoints ready for frontend integration"
./tm complete $API_TASK

# Agent 4 - Frontend specialist (different session)
export TM_AGENT_ID="claude_frontend" 
# API completion unblocks UI task
./tm join $UI_TASK
./tm context $UI_TASK  # Sees security requirements and API details
./tm share $UI_TASK "Building login/register components"

# Check for any critical discoveries
./tm watch  # Sees security rate limiting requirement
./tm share $UI_TASK "Added user feedback for rate limiting"
./tm complete $UI_TASK --impact-review
```

### File Reference Best Practices

Always link tasks to specific files:
```bash
# Single file
./tm add "Fix login validation" --file src/auth/validators.py:45

# File range  
./tm add "Refactor user model" --file src/models/user.py:100:200

# Multiple files
./tm add "Update auth flow" --file src/auth/login.py --file src/auth/middleware.py
```

### Error Handling & Recovery

If Task Orchestrator commands fail:
1. Check if database is initialized: `./tm init`
2. Verify permissions on .task-orchestrator/
3. Check for lock file: `rm .task-orchestrator/.lock` (if stale)
4. Ensure src/ directory exists with tm_production.py

### Notification Management

Check notifications regularly:
```bash
./tm watch  # See recent events
```

Common notification types:
- **unblocked**: Your task's dependencies completed
- **discovery**: Critical findings from other agents  
- **impact**: Tasks completed with potential effects on your work

## 🔒 END OF TASK ORCHESTRATOR SECTION

---

## Project-Specific Instructions

[Your existing project instructions continue here...]

### Project Overview
[Your project description]

### Development Guidelines  
[Your coding standards]

### Testing Requirements
[Your testing approach]

---

*Task Orchestrator Integration - Production Ready v2.0.0*