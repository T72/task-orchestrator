# Task Orchestrator Database Schema

This document describes the complete database schema for Task Orchestrator.

## Schema Version

**Current Version**: 1.0  
**Last Updated**: 2025-08-20  
**Location**: Implementation in `src/tm_production.py`

> **⚠️ IMPORTANT NOTICE**: This documentation describes both the **current implementation** and **planned enhancements**. Tables marked as "PLANNED" are documented for future implementation but are not yet in the codebase.

## Core Tables (IMPLEMENTED)

### 1. `tasks` Table

Stores all task information.

```sql
CREATE TABLE IF NOT EXISTS tasks (
    id TEXT PRIMARY KEY,           -- 8-character unique identifier
    title TEXT NOT NULL,            -- Task title/description
    description TEXT,               -- Detailed description (optional)
    status TEXT DEFAULT 'pending',  -- Task status: pending|in_progress|completed|blocked|cancelled
    priority TEXT DEFAULT 'medium', -- Priority: low|medium|high|critical
    assignee TEXT,                  -- Agent/person assigned to task
    created_at TEXT NOT NULL,       -- ISO 8601 timestamp
    updated_at TEXT NOT NULL,       -- ISO 8601 timestamp
    completed_at TEXT               -- ISO 8601 timestamp when completed
)
```

**Constraints**:
- `id`: Must be exactly 8 characters (enforced in application)
- `title`: Cannot be empty, max 500 characters
- `status`: Must be one of the defined values
- `priority`: Must be one of the defined values

### 2. `dependencies` Table

Manages task dependency relationships.

**Current Implementation:**
```sql
CREATE TABLE IF NOT EXISTS dependencies (
    task_id TEXT NOT NULL,     -- Task that has the dependency
    depends_on TEXT NOT NULL,   -- Task that must complete first
    PRIMARY KEY (task_id, depends_on)
)
```

**Note**: Foreign key constraints are not currently enforced in the implementation but are planned for future versions.

**Constraints (enforced in application)**:
- No circular dependencies
- Self-dependencies not allowed
- Composite primary key ensures unique dependency pairs

### 3. `notifications` Table

Stores notifications for agents.

```sql
CREATE TABLE IF NOT EXISTS notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT,              -- Target agent (NULL for broadcast)
    task_id TEXT,               -- Related task
    type TEXT NOT NULL,         -- Notification type
    message TEXT NOT NULL,      -- Notification message
    created_at TEXT NOT NULL,   -- ISO 8601 timestamp
    read BOOLEAN DEFAULT 0      -- Read status
)
```

**Notification Types**:
- `task_completed`: Task completion notifications
- `task_unblocked`: Dependency resolved notifications
- `task_assigned`: Assignment notifications
- `discovery`: Cross-task discoveries
- `critical`: Critical alerts

### 4. `participants` Table

Tracks which agents are participating in tasks.

```sql
CREATE TABLE IF NOT EXISTS participants (
    task_id TEXT NOT NULL,     -- Task ID
    agent_id TEXT NOT NULL,     -- Agent identifier
    joined_at TEXT NOT NULL,    -- ISO 8601 timestamp
    PRIMARY KEY (task_id, agent_id),
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
)
```

## Extended Tables (PLANNED - Not Yet Implemented)

### 5. `context_updates` Table (PLANNED)

**Note**: Currently, context sharing is implemented using YAML files in `.task-orchestrator/contexts/` directory. This table is planned for future database-based implementation.

```sql
CREATE TABLE IF NOT EXISTS context_updates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT NOT NULL,
    agent_id TEXT NOT NULL,
    update_type TEXT NOT NULL,  -- 'shared'|'private'|'discovery'
    content TEXT NOT NULL,
    created_at TEXT NOT NULL,
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
)
```

**Current Implementation**: 
- Context stored in `.task-orchestrator/contexts/{task_id}.yaml`
- Private notes stored in `.task-orchestrator/private_notes/{task_id}.yaml`

**Update Types**:
- `shared`: Public coordination information
- `private`: Internal agent reasoning
- `discovery`: Important findings for all agents

### 6. `file_refs` Table (PLANNED)

Links tasks to specific file locations. Currently file references are stored as part of task creation but not in a separate table.

```sql
CREATE TABLE IF NOT EXISTS file_refs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT NOT NULL,
    file_path TEXT NOT NULL,
    line_start INTEGER,         -- Optional: specific line reference
    line_end INTEGER,           -- Optional: end of range
    context TEXT,               -- Optional: why this file matters
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
)
```

### 7. `audit_log` Table (PLANNED)

Tracks all changes for accountability. Not yet implemented in current version.

```sql
CREATE TABLE IF NOT EXISTS audit_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type TEXT NOT NULL,  -- 'task'|'dependency'|'notification'
    entity_id TEXT NOT NULL,
    action TEXT NOT NULL,        -- 'create'|'update'|'delete'
    agent_id TEXT NOT NULL,
    changes TEXT,                -- JSON of what changed
    timestamp TEXT NOT NULL
)
```

## Indexes (PLANNED)

**Note**: These indexes are planned for performance optimization but are not yet implemented in the current version.

```sql
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_assignee ON tasks(assignee);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_dependencies_task ON dependencies(task_id);
CREATE INDEX idx_dependencies_depends ON dependencies(depends_on);
CREATE INDEX idx_notifications_agent ON notifications(agent_id, read);
CREATE INDEX idx_context_task ON context_updates(task_id);
CREATE INDEX idx_file_refs_task ON file_refs(task_id);
```

## Current Implementation vs Documentation

### What's Actually Implemented
- ✅ `tasks` table (core functionality)
- ✅ `dependencies` table (without foreign keys)
- ✅ `notifications` table
- ✅ `participants` table
- ✅ Context sharing via YAML files (not database)
- ✅ Private notes via YAML files (not database)

### What's Planned but Not Implemented
- ❌ Foreign key constraints
- ❌ CHECK constraints  
- ❌ Performance indexes
- ❌ `context_updates` table (using YAML files instead)
- ❌ `file_refs` table
- ❌ `audit_log` table

### File-Based Storage (Current)
Instead of some database tables, the current implementation uses files:
- **Contexts**: `.task-orchestrator/contexts/{task_id}.yaml`
- **Private Notes**: `.task-orchestrator/private_notes/{task_id}.yaml`
- **Discoveries**: Stored in context YAML files

## Migration Guidelines

When modifying the schema:

1. **Backward Compatibility**: Ensure existing databases can be migrated
2. **Version Tracking**: Update the schema version at the top of this document
3. **Migration Script**: Create a migration function in `src/tm_production.py`
4. **Testing**: Test with both new and existing databases
5. **Documentation**: Update this file with changes

### Example Migration Pattern

```python
def migrate_schema(conn, from_version, to_version):
    """Migrate database schema between versions"""
    if from_version < 2 and to_version >= 2:
        # Example: Add new column with default value
        conn.execute("""
            ALTER TABLE tasks 
            ADD COLUMN tags TEXT DEFAULT ''
        """)
    # Add more migration steps as needed
```

## Data Integrity Rules

### Business Rules Enforced

1. **Task Lifecycle**:
   - Tasks start as `pending`
   - Can transition through `in_progress` to `completed`
   - `blocked` status when dependencies exist
   - `cancelled` is terminal state

2. **Dependency Rules**:
   - No circular dependencies
   - Dependencies must exist before referencing
   - Completing a task unblocks dependents

3. **Agent Identification**:
   - Agent IDs are auto-generated or from `TM_AGENT_ID` environment variable
   - Format: `[role]_[specialty]_[session]`

4. **Timestamp Format**:
   - All timestamps use ISO 8601 format
   - UTC timezone recommended
   - Example: `2025-08-20T10:30:00Z`

## Database Location

- **Default Path**: `.task-orchestrator/tasks.db`
- **Environment Variable**: `TM_DB_PATH` to override
- **Permissions**: Must be writable by user
- **Backup**: Recommended before schema changes

## Performance Considerations

1. **Locking**: SQLite uses file locking, minimize transaction time
2. **Batch Operations**: Group multiple operations in single transaction
3. **Index Usage**: Ensure queries use appropriate indexes
4. **VACUUM**: Periodically run `VACUUM` to optimize database

## Troubleshooting

### Common Issues

1. **Database Locked**:
   - Increase timeout: `export TM_LOCK_TIMEOUT=30`
   - Check for orphaned locks

2. **Migration Failures**:
   - Backup database before migration
   - Check schema version compatibility

3. **Performance Issues**:
   - Run `ANALYZE` to update statistics
   - Check index usage with `EXPLAIN QUERY PLAN`

## Related Documentation

- [Developer Guide](../developer-guide.md) - Full development documentation
- [API Reference](./api-reference.md) - Command-line interface
- [Contributing](../../CONTRIBUTING.md) - How to contribute changes