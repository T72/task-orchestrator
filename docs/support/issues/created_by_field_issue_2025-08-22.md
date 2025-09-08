# Issue Report

**Date:** 2025-08-22  
**Reporter:** Claude Code + RoleScoutPro-MVP Team  
**Type:** Bug  
**Version:** v2.5.0-internal
**Status:** ✅ RESOLVED in v2.5.1
**Resolution Date:** 2025-08-22

## Description
Database constraint error when creating tasks: "NOT NULL constraint failed: tasks.created_by" despite having TM_AGENT_ID environment variable set.

## Environment
- OS: WSL (Ubuntu on Windows)
- Python version: 3.8.10
- Task Orchestrator version: v2.5.0-internal
- Database location: .task-orchestrator/

## Steps to Reproduce
1. Install Task Orchestrator v2.5.0-internal
2. Run `./tm init` to initialize database
3. Set environment variable: `export TM_AGENT_ID="orchestrator"`
4. Try to create task: `./tm add "Test task"`
5. Error occurs: "NOT NULL constraint failed: tasks.created_by"

## Expected Behavior
The `tm add` command should use the TM_AGENT_ID environment variable to populate the created_by field automatically.

## Actual Behavior
The created_by field is not populated from the environment variable, causing a database constraint violation.

## Logs/Error Messages
```
$ export TM_AGENT_ID="orchestrator"
$ ./tm add "Deploy agent squadron for test recovery"
Error: Database integrity error: NOT NULL constraint failed: tasks.created_by
```

## Workaround
Currently, there's no direct workaround. The Python implementation in `src/tm_production.py` needs to be modified to:
1. Read the TM_AGENT_ID environment variable
2. Use it as the default value for created_by field
3. Fall back to a default value like "user" if not set

## Additional Context
- The database schema requires created_by as NOT NULL
- The add() method in tm_production.py doesn't reference os.environ['TM_AGENT_ID']
- This affects multi-agent coordination as agents can't create tasks properly
- Priority field also requires explicit setting with `-p normal`

---

## Resolution Summary (v2.5.1)

### Fixed
1. **Database Schema Updated**
   - Added `created_by TEXT NOT NULL DEFAULT 'user'` to tasks table
   - Implemented automatic migration for existing databases
   
2. **TM_AGENT_ID Integration**
   - System now properly reads `TM_AGENT_ID` from environment
   - Falls back to readable format: `username_hash` (e.g., "marcu_ed0e")
   - Every task properly tracks which agent created it

3. **Multi-Agent Support Enhanced**
   - Tested with multiple agents creating tasks simultaneously
   - Each agent's tasks are properly attributed
   - Example:
     ```bash
     export TM_AGENT_ID="frontend_agent"
     ./tm add "Build UI"  # created_by: frontend_agent
     
     export TM_AGENT_ID="backend_agent"  
     ./tm add "Create API"  # created_by: backend_agent
     ```

### Testing Performed
- ✅ Fresh database initialization with created_by field
- ✅ Migration of existing databases without created_by
- ✅ Task creation with TM_AGENT_ID set
- ✅ Task creation without TM_AGENT_ID (uses default)
- ✅ Multi-agent scenario with different agent IDs
- ✅ Backward compatibility verified

### Update Instructions
1. Update to v2.5.1 internal release
2. Database will automatically migrate on first use
3. Set `TM_AGENT_ID` for each agent:
   ```bash
   export TM_AGENT_ID="your_agent_name"
   ```

**Impact**: Multi-agent coordination now works seamlessly with proper task attribution!