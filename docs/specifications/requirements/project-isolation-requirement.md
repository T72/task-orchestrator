# Project Isolation Requirement (v2.4.0)

## Requirement Addition

### FR-040: Project-Local Database Isolation
**User Story**: As a developer working on multiple projects, I need each project's tasks to be completely isolated from other projects to prevent contamination and maintain clear project boundaries.

**Problem Statement**: 
- Previous versions (≤v2.3.0) used a global database at `~/.task-orchestrator/tasks.db`
- This caused task bleeding between unrelated projects
- Made Task Orchestrator unusable for multi-project development
- Created confusion when context switching between projects

**Acceptance Criteria**:
- ✅ Each project MUST have its own isolated database
- ✅ Default location: `./.task-orchestrator/tasks.db` (project-local)
- ✅ No tasks from Project A should appear when working in Project B
- ✅ Allow environment variable override via `TM_DB_PATH` for special cases
- ✅ Maintain backward compatibility through environment variable

**Implementation**:
```python
# Default behavior (NEW)
self.db_dir = Path.cwd() / ".task-orchestrator"

# Override via environment (for backward compatibility)
if os.environ.get('TM_DB_PATH'):
    self.db_dir = Path(os.environ.get('TM_DB_PATH'))
```

**Priority**: CRITICAL
**Status**: ✅ Implemented
**Dependencies**: None
**Breaking Change**: Yes (but with backward compatibility via TM_DB_PATH)

### NFR-006: Multi-Project Workspace Support
**User Story**: As a developer, I need to work on multiple projects simultaneously without task contamination.

**Acceptance Criteria**:
- Support concurrent task management in different terminal sessions
- Each project workspace remains completely isolated
- No shared state between projects (except when explicitly configured)
- Database locks scoped to project, not global

**Priority**: HIGH
**Status**: ✅ Implemented

## Rationale

This requirement addresses a **fundamental design flaw** that made Task Orchestrator unsuitable for real-world development where developers commonly work on multiple projects.

## Migration Path

1. **New Projects**: Automatically use project-local database
2. **Existing Projects**: Can migrate tasks or continue using global database via `TM_DB_PATH=~/.task-orchestrator`
3. **Hybrid Mode**: Set `TM_DB_PATH` per project as needed

## Impact Analysis

### Positive Impacts
- ✅ Enables true multi-project development
- ✅ Prevents task contamination
- ✅ Allows project-specific task management
- ✅ Enables including task history in version control (optional)
- ✅ Simplifies project cleanup (just delete `.task-orchestrator/`)

### Considerations
- ⚠️ Existing users need to be aware of the change
- ⚠️ Documentation must be updated
- ⚠️ Global task coordination (if needed) requires explicit configuration

## Testing Requirements

1. **Isolation Test**: Create tasks in Project A, verify they don't appear in Project B
2. **Migration Test**: Verify TM_DB_PATH override works for backward compatibility
3. **Concurrent Test**: Run task operations in multiple projects simultaneously
4. **Cleanup Test**: Verify project deletion removes all task data

## Documentation Requirements

1. Update README with new default behavior
2. Create migration guide for existing users
3. Document TM_DB_PATH environment variable
4. Update quick start guide

## Version History

- **v2.4.0**: Introduced project-local database isolation (THIS CHANGE)
- **v2.3.0**: Last version with global database default
- **v1.0.0**: Initial release with global database

## Approval

This requirement is **PRE-APPROVED** as it fixes a critical usability issue that prevents Task Orchestrator from being used in real-world multi-project scenarios.