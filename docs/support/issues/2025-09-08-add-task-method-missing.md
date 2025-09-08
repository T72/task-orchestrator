# Issue Report Template

## Date: 2025-09-08
## Version: 2.8.0-internal (migrated from 2.7.2)

## Issue Summary
TaskManager object missing 'add_task' method causing AttributeError when using `./tm add` command

## Category
- [x] bug
- [ ] performance
- [ ] compatibility
- [ ] agent-coordination

## Priority
- [x] Critical
- [ ] High
- [ ] Medium
- [ ] Low

## Steps to Reproduce
1. Navigate to RoleScoutPro-MVP project directory
2. Set TM_AGENT_ID environment variable: `export TM_AGENT_ID="session-summary-specialist"`
3. Execute: `./tm add "Create task" --context "WHY: test WHAT: test DONE: test"`
4. Observe AttributeError

## Expected vs Actual
**Expected**: Task should be created successfully and return task ID
**Actual**: Python traceback with AttributeError: 'TaskManager' object has no attribute 'add_task'

## Error Messages
```
Traceback (most recent call last):
  File "/mnt/d/Dropbox/Private/Persönlich/VSCodeEnv/projects/IT ThinkTank Lab/RoleScoutPro-MVP/./tm", line 399, in <module>
    main()
  File "/mnt/d/Dropbox/Private/Persönlich/VSCodeEnv/projects/IT ThinkTank Lab/RoleScoutPro-MVP/./tm", line 140, in main
    task_id = tm.add_task(
              ^^^^^^^^^^^
AttributeError: 'TaskManager' object has no attribute 'add_task'
```

## Environment Details
- **Operating System**: Windows 11 WSL2
- **Python Version**: 3.x
- **Installation Method**: Migration from v2.7.2 to v2.8.0
- **Project Location**: `/mnt/d/Dropbox/Private/Persönlich/VSCodeEnv/projects/IT ThinkTank Lab/RoleScoutPro-MVP`
- **Migration Context**: Previous session involved Task Orchestrator migration that may have introduced incompatibility

## Additional Context
- Issue occurred immediately after Task Orchestrator v2.8.0 migration
- Previous v2.7.2 installation was working correctly
- The wrapper script `tm` appears to be calling `tm.add_task()` but TaskManager class doesn't have this method
- This blocks all task creation functionality and violates Protected Rules requiring Task Orchestrator usage

## Impact
- **Critical Impact**: Cannot create tasks, blocking development workflow
- **Hook Enforcement**: Task creation blocked by enforce-task-orchestrator.sh hook
- **Session Continuity**: Cannot use Task Orchestrator for session management
- **Development Velocity**: 4x-5x velocity improvements unavailable

## Suspected Root Cause
Method name mismatch between wrapper script expectations and actual TaskManager implementation. Possible causes:
1. Migration script didn't update wrapper compatibility
2. TaskManager class method renamed in v2.8.0
3. Import or class instantiation issue

## Technical Analysis
**Root Cause Identified**: Method name mismatch between wrapper script and TaskManager class
- Wrapper script calls: `tm.add_task(description=...)`
- TaskManager class provides: `tm.add(title=..., description=...)`

**Recommended Solution**:
Update wrapper script line ~140 to use correct method signature:
```python
task_id = tm.add(
    title=description,
    description=context if context else "",
    assignee=assignee,
    depends_on=depends_on if depends_on else None
)
```

**Additional Finding**: EnforcementEngine lacks `check_override` method
- Wrapper expects: `enforcement_engine.check_override(assignee, description)`
- Actual class methods: See enforcement.py for available methods

## Resolution Status
**Status**: ✅ RESOLVED - Fixed and Deployed
**Resolution Date**: 2025-09-08
**Fix Deployed**: Updated tm wrapper script deployed to user's project
**Verification**: Task creation tested successfully - Task ID db172b69 created

## Implementation Details
**Root Cause**: User had outdated wrapper script from older Task Orchestrator version
**Solution Applied**: Deployed current tm wrapper script with correct method calls
- Updated from: `tm.add_task()` (old, non-existent method)
- Updated to: `tm.add()` (current, correct method)
**Testing Results**: ✅ Task creation working correctly without errors

## Fix Coverage
- ✅ Method name compatibility resolved
- ✅ Enforcement system error handling improved
- ✅ Full command functionality restored
- ✅ User workflow unblocked

---
*Save as: docs/support/issues/2025-09-08-add-task-method-missing.md*