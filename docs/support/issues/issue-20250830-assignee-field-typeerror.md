# Issue Report

**Date:** 2025-08-30  
**Reporter:** Dev-Kit Integration Team  
**Type:** Bug  
**Version:** v2.6.0-internal

## Description
TaskManager.add() method raises TypeError when templates or wizard attempt to pass the 'assignee' parameter, preventing template application and wizard quick mode from functioning correctly.

## Environment
- OS: WSL
- Python version: 3.8+
- Task Orchestrator version: v2.6.0-internal
- Database location: .task-orchestrator/

## Steps to Reproduce
1. Extract and install Task Orchestrator v2.6.0-internal package
2. Run `./tm init` to initialize database
3. Attempt to apply any bundled template:
   ```bash
   ./tm template apply feature-development --var feature_name=test --var assignee=developer
   ```
   OR
4. Run wizard quick mode and include assignee:
   ```bash
   ./tm wizard --quick
   # Enter: Test task @developer
   ```

## Expected Behavior
Templates should successfully create tasks with the assignee field populated as specified in the template YAML files, and the wizard should accept assignee notation.

## Actual Behavior
Both operations fail immediately with TypeError indicating that TaskManager.add() received an unexpected 'assignee' keyword argument.

## Logs/Error Messages
```
Traceback (most recent call last):
  File "./tm", line 697, in main
    task_id = tm.add(title,
             ^^^^^^^^^^^^^
TypeError: TaskManager.add() got an unexpected keyword argument 'assignee'

Error applying template: TaskManager.add() got an unexpected keyword argument 'assignee'
```

Wizard error:
```
Traceback (most recent call last):
  File "./tm", line 757, in main
    success = wizard.quick_start()
              ^^^^^^^^^^^^^^^^^^^^
  File "src/interactive_wizard.py", line 483, in quick_start
    task_id = self.task_manager.add(
              ^^^^^^^^^^^^^^^^^^^^^^
TypeError: TaskManager.add() got an unexpected keyword argument 'assignee'
```

## Workaround
Create tasks manually without using templates or wizard:
```bash
./tm add "Task title" -d "Description" -p high
```

For templates, remove or comment out the assignee field from YAML files before applying.

## Additional Context
- All 5 bundled templates contain assignee fields and are affected
- Custom templates with assignee fields also fail
- The issue appears to be a mismatch between template/wizard expectations and the TaskManager.add() method signature
- Multi-agent 'created_by' field works correctly, suggesting assignee may have been overlooked
- This significantly impacts the v2.6.0 template and wizard features advertised in the release notes

## Resolution

**Date Resolved:** 2025-08-30  
**Resolved By:** Development Team  
**Version Fixed:** v2.6.1-internal

### Root Cause
The TaskManager.add() method signature was missing the `assignee` parameter, even though:
- The database schema included an `assignee` field
- The update() and list() methods supported assignee functionality
- Templates and wizard were designed to use assignee field

Additionally, the wizard was incorrectly passing a non-existent `tags` parameter.

### Fix Applied
1. **Updated TaskManager.add() method signature** in `src/tm_production.py`:
   - Added `assignee: str = None` parameter
   - Updated all INSERT statements to include assignee field
   - Added @implements COLLAB-003 for task assignment tracking

2. **Updated wrapper script** (`tm`):
   - Added `--assignee` argument parsing to the add command
   - Fixed template application to pass correct parameters
   - Updated usage documentation

3. **Fixed Interactive Wizard** (`src/interactive_wizard.py`):
   - Removed invalid `tags` parameter from all add() calls
   - Ensured proper parameter passing for assignee field

### Testing Performed
- ✅ Direct task creation with assignee: `./tm add "Task" --assignee developer`
- ✅ Template application with assignee variable
- ✅ Wizard quick mode with @assignee notation
- ✅ Verified assignee field properly stored and retrieved

### Update Instructions
Users should update to the latest version which includes these fixes. No database migration is required as the schema already supported the assignee field.