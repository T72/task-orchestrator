# Issue Report

**Date:** 2025-08-30  
**Reporter:** Dev-Kit Integration Team  
**Type:** Bug  
**Version:** v2.6.0-internal-20250823  
**Severity:** Medium  
**Status:** Open

## Description
TaskManager.add() method throws TypeError when templates or wizard attempt to pass the 'assignee' parameter, causing template application and wizard quick mode to fail.

## Environment
- OS: WSL (Linux 6.6.87.2-microsoft-standard-WSL2)
- Python version: Python 3.x
- Task Orchestrator version: v2.6.0-internal-20250823
- Installation location: /mnt/d/Dropbox/Private/Persönlich/VSCodeEnv/projects/IT ThinkTank Lab/Dev-Kit

## Steps to Reproduce

### Method 1: Template Application
1. Initialize Task Orchestrator: `./tm init`
2. Attempt to apply any template with assignee field:
   ```bash
   ./tm template apply feature-development --var feature_name=test --var assignee=developer
   ```

### Method 2: Quick Wizard
1. Run quick wizard: `./tm wizard --quick`
2. Enter task with assignee: `Test task @developer`

## Expected Behavior
- Templates should successfully create tasks with assignee field populated
- Wizard should accept assignee notation and create tasks accordingly

## Actual Behavior
Both operations fail with:
```python
TypeError: TaskManager.add() got an unexpected keyword argument 'assignee'
```

## Error Details

### Template Error Stack Trace:
```python
Traceback (most recent call last):
  File "./tm", line 697, in main
    task_id = tm.add(title,
             ^^^^^^^^^^^^^
TypeError: TaskManager.add() got an unexpected keyword argument 'assignee'
```

### Wizard Error Stack Trace:
```python
Traceback (most recent call last):
  File "./tm", line 757, in main
    success = wizard.quick_start()
              ^^^^^^^^^^^^^^^^^^^^
  File "src/interactive_wizard.py", line 483, in quick_start
    task_id = self.task_manager.add(
              ^^^^^^^^^^^^^^^^^^^^^^
TypeError: TaskManager.add() got an unexpected keyword argument 'assignee'
```

## Impact
- All 5 bundled templates (bug-fix, code-review, deployment, documentation, feature-development) contain assignee fields and cannot be applied
- Quick wizard mode is unusable when assignee is specified
- Custom templates with assignee fields also fail

## Root Cause Analysis
The issue appears to be a mismatch between:
1. Template system expecting TaskManager.add() to accept 'assignee' parameter
2. Interactive wizard expecting TaskManager.add() to accept 'assignee' parameter  
3. Actual TaskManager.add() method signature not including 'assignee' parameter

## Workaround
1. Create tasks manually without using templates or wizard
2. Remove assignee field from custom templates
3. Avoid using assignee notation in wizard

## Suggested Fix
Add 'assignee' parameter to TaskManager.add() method signature and handle it appropriately in the database schema. The field appears to already exist in templates and wizard code, suggesting it may have been overlooked in the core TaskManager implementation.

## Additional Context
- Issue discovered during Dev-Kit integration with Task Orchestrator
- The 'created_by' field for multi-agent support works correctly
- Database migration for v2.6.0 successfully adds 'created_by' field but doesn't appear to include 'assignee' field

## Reproduction Files
- All templates in `.task-orchestrator/templates/` directory exhibit this issue
- Custom templates created for Dev-Kit integration also affected

## Priority
Medium - Core functionality works but major v2.6.0 features (templates and wizard) are significantly impaired

---

**Reported via Dev-Kit Integration Testing**  
**Reference:** TM-2.6-0001