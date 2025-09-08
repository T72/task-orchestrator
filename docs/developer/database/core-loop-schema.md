# Task Orchestrator Database Schema

## Overview

Task Orchestrator uses SQLite for data persistence, providing ACID compliance and excellent performance for task management workloads. The Core Loop features introduced in v2.3 extend the schema with additional fields for success criteria, feedback, and metrics.

## Table of Contents

- [Database Overview](#database-overview)
- [Core Tables](#core-tables)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Data Types and Constraints](#data-types-and-constraints)
- [Indexes and Performance](#indexes-and-performance)
- [Migration History](#migration-history)
- [JSON Data Structures](#json-data-structures)
- [Query Examples](#query-examples)

## Database Overview

**Database Engine**: SQLite 3.x  
**Location**: `~/.task-orchestrator/tasks.db`  
**Configuration**: WAL mode enabled, optimized for WSL environments  
**Character Set**: UTF-8  
**Transaction Isolation**: SERIALIZABLE  

### Database Configuration

```sql
-- Performance optimizations applied at startup
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA cache_size=10000;
PRAGMA foreign_keys=ON;
PRAGMA temp_store=MEMORY;
PRAGMA mmap_size=30000000000;
```

## Core Tables

### tasks

The primary table storing all task information, including Core Loop fields.

```sql
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,                 -- 8-character hex ID
    title TEXT NOT NULL,                 -- Task description
    description TEXT,                    -- Detailed description
    status TEXT DEFAULT 'pending',      -- Current status
    priority TEXT DEFAULT 'medium',     -- Priority level
    assignee TEXT,                       -- Assigned agent/user
    created_at TEXT NOT NULL,            -- ISO 8601 timestamp
    updated_at TEXT NOT NULL,            -- ISO 8601 timestamp
    completed_at TEXT,                   -- ISO 8601 timestamp
    
    -- Core Loop fields (v2.3+)
    success_criteria TEXT,               -- JSON array of criteria
    feedback_quality INTEGER,            -- 1-5 scale
    feedback_timeliness INTEGER,         -- 1-5 scale
    feedback_notes TEXT,                 -- Feedback comments
    completion_summary TEXT,             -- Summary and learnings
    deadline TEXT,                       -- ISO 8601 deadline
    estimated_hours REAL,               -- Time estimate
    actual_hours REAL                   -- Actual time spent
);
```

**Field Details:**

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique 8-character hex identifier |
| `title` | TEXT | NOT NULL | Human-readable task title |
| `description` | TEXT | NULL | Optional detailed description |
| `status` | TEXT | CHECK IN ('pending', 'in_progress', 'completed', 'blocked') | Current task state |
| `priority` | TEXT | CHECK IN ('low', 'medium', 'high', 'critical') | Task priority |
| `assignee` | TEXT | NULL | Agent or user ID |
| `created_at` | TEXT | NOT NULL | Creation timestamp (ISO 8601) |
| `updated_at` | TEXT | NOT NULL | Last modification timestamp |
| `completed_at` | TEXT | NULL | Completion timestamp |
| `success_criteria` | TEXT | NULL | JSON array of success criteria objects |
| `feedback_quality` | INTEGER | CHECK BETWEEN 1 AND 5 | Quality score |
| `feedback_timeliness` | INTEGER | CHECK BETWEEN 1 AND 5 | Timeliness score |
| `feedback_notes` | TEXT | NULL | Additional feedback comments |
| `completion_summary` | TEXT | NULL | Task completion summary |
| `deadline` | TEXT | NULL | Task deadline (ISO 8601) |
| `estimated_hours` | REAL | CHECK >= 0 | Estimated completion time |
| `actual_hours` | REAL | CHECK >= 0 | Actual time spent |

### dependencies

Stores task dependency relationships.

```sql
CREATE TABLE dependencies (
    task_id TEXT NOT NULL,              -- Dependent task ID
    depends_on TEXT NOT NULL,           -- Dependency task ID
    PRIMARY KEY (task_id, depends_on),
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    FOREIGN KEY (depends_on) REFERENCES tasks(id) ON DELETE CASCADE
);
```

**Purpose**: Enforces task ordering and enables automatic blocking/unblocking.

### notifications

Stores system notifications for agents.

```sql
CREATE TABLE notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT,                      -- Target agent
    task_id TEXT,                       -- Related task
    type TEXT NOT NULL,                 -- Notification type
    message TEXT NOT NULL,              -- Notification content
    created_at TEXT NOT NULL,           -- Creation timestamp
    read BOOLEAN DEFAULT 0,             -- Read status
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);
```

**Notification Types**:
- `unblocked`: Task dependencies completed
- `impact`: Related files changed
- `discovery`: Critical finding shared
- `completed`: Watched task finished

### participants

Tracks task collaboration participation.

```sql
CREATE TABLE participants (
    task_id TEXT NOT NULL,              -- Task ID
    agent_id TEXT NOT NULL,             -- Participant agent
    joined_at TEXT NOT NULL,            -- Join timestamp
    PRIMARY KEY (task_id, agent_id),
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);
```

**Purpose**: Enables multi-agent collaboration tracking.

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         tasks                               │
├─────────────────────────────────────────────────────────────┤
│ PK  id                    TEXT                              │
│     title                 TEXT NOT NULL                     │
│     description           TEXT                              │
│     status                TEXT DEFAULT 'pending'           │
│     priority              TEXT DEFAULT 'medium'            │
│     assignee              TEXT                              │
│     created_at            TEXT NOT NULL                     │
│     updated_at            TEXT NOT NULL                     │
│     completed_at          TEXT                              │
│     success_criteria      TEXT                              │
│     feedback_quality      INTEGER                           │
│     feedback_timeliness   INTEGER                           │
│     feedback_notes        TEXT                              │
│     completion_summary    TEXT                              │
│     deadline              TEXT                              │
│     estimated_hours       REAL                              │
│     actual_hours          REAL                              │
└─────────────────────────────────────────────────────────────┘
                                    │
                                    │ 1:N
                                    ▼
┌─────────────────────────────────────────────────────────────┐
│                    dependencies                             │
├─────────────────────────────────────────────────────────────┤
│ PK  task_id              TEXT NOT NULL                      │
│ PK  depends_on           TEXT NOT NULL                      │
│ FK  task_id         →    tasks(id)                          │
│ FK  depends_on      →    tasks(id)                          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   notifications                             │
├─────────────────────────────────────────────────────────────┤
│ PK  id                   INTEGER AUTOINCREMENT              │
│     agent_id             TEXT                               │
│ FK  task_id         →    tasks(id)                          │
│     type                 TEXT NOT NULL                      │
│     message              TEXT NOT NULL                      │
│     created_at           TEXT NOT NULL                      │
│     read                 BOOLEAN DEFAULT 0                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   participants                              │
├─────────────────────────────────────────────────────────────┤
│ PK  task_id              TEXT NOT NULL                      │
│ PK  agent_id             TEXT NOT NULL                      │
│     joined_at            TEXT NOT NULL                      │
│ FK  task_id         →    tasks(id)                          │
└─────────────────────────────────────────────────────────────┘
```

## Data Types and Constraints

### Status Values
```sql
CHECK (status IN ('pending', 'in_progress', 'completed', 'blocked'))
```

### Priority Values
```sql
CHECK (priority IN ('low', 'medium', 'high', 'critical'))
```

### Feedback Constraints
```sql
CHECK (feedback_quality IS NULL OR feedback_quality BETWEEN 1 AND 5)
CHECK (feedback_timeliness IS NULL OR feedback_timeliness BETWEEN 1 AND 5)
```

### Time Constraints
```sql
CHECK (estimated_hours IS NULL OR estimated_hours >= 0)
CHECK (actual_hours IS NULL OR actual_hours >= 0)
```

### Date Format
All timestamp fields use ISO 8601 format: `YYYY-MM-DDTHH:MM:SSZ`

## Indexes and Performance

### Recommended Indexes

```sql
-- Performance indexes for common queries
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_assignee ON tasks(assignee);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_deadline ON tasks(deadline);
CREATE INDEX IF NOT EXISTS idx_tasks_created ON tasks(created_at);

-- Composite indexes for complex queries
CREATE INDEX IF NOT EXISTS idx_tasks_status_assignee ON tasks(status, assignee);
CREATE INDEX IF NOT EXISTS idx_tasks_status_priority ON tasks(status, priority);

-- Dependency indexes
CREATE INDEX IF NOT EXISTS idx_deps_task ON dependencies(task_id);
CREATE INDEX IF NOT EXISTS idx_deps_depends ON dependencies(depends_on);

-- Notification indexes
CREATE INDEX IF NOT EXISTS idx_notifications_agent ON notifications(agent_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(agent_id, read);
```

### Query Performance Guidelines

**Fast Queries** (< 1ms):
- Single task lookup by ID
- Status-based filtering
- Assignee-based filtering

**Medium Queries** (1-10ms):
- Complex filtering with multiple conditions
- Dependency tree traversal
- Aggregate metrics calculation

**Slow Queries** (10-100ms):
- Full-text search in descriptions
- Complex date range queries
- Large result set exports

## Migration History

### Version 2.3.0 Migration

The Core Loop migration adds the following fields to the tasks table:

```sql
-- Migration 001: Add Core Loop fields
ALTER TABLE tasks ADD COLUMN success_criteria TEXT;
ALTER TABLE tasks ADD COLUMN feedback_quality INTEGER;
ALTER TABLE tasks ADD COLUMN feedback_timeliness INTEGER;
ALTER TABLE tasks ADD COLUMN feedback_notes TEXT;
ALTER TABLE tasks ADD COLUMN completion_summary TEXT;
ALTER TABLE tasks ADD COLUMN deadline TEXT;
ALTER TABLE tasks ADD COLUMN estimated_hours REAL;
ALTER TABLE tasks ADD COLUMN actual_hours REAL;

-- Add constraints
CREATE TRIGGER feedback_quality_check
BEFORE UPDATE ON tasks
WHEN NEW.feedback_quality IS NOT NULL
BEGIN
    SELECT CASE
        WHEN NEW.feedback_quality < 1 OR NEW.feedback_quality > 5
        THEN RAISE(ABORT, 'feedback_quality must be between 1 and 5')
    END;
END;
```

### Migration Tracking

```sql
-- Migration tracking table (automatically created)
CREATE TABLE schema_version (
    version INTEGER PRIMARY KEY,
    applied_at TEXT NOT NULL,
    description TEXT
);
```

## JSON Data Structures

### Success Criteria Format

```json
[
  {
    "criterion": "Human-readable description",
    "measurable": "boolean_expression_or_literal"
  },
  {
    "criterion": "All tests pass",
    "measurable": "true"
  },
  {
    "criterion": "Performance acceptable",
    "measurable": "response_time < 200"
  }
]
```

### Progress History Format (Future)

```json
[
  {
    "timestamp": "2025-08-20T10:30:00Z",
    "message": "Started investigation",
    "agent_id": "abc12345"
  },
  {
    "timestamp": "2025-08-20T11:15:00Z",
    "message": "25% - Found root cause",
    "agent_id": "abc12345"
  }
]
```

## Query Examples

### Basic Task Queries

```sql
-- Find pending tasks for an agent
SELECT id, title, priority, deadline
FROM tasks 
WHERE status = 'pending' 
  AND assignee = 'agent_123'
ORDER BY priority DESC, deadline ASC;

-- Find overdue tasks
SELECT id, title, assignee, deadline
FROM tasks
WHERE status != 'completed'
  AND deadline IS NOT NULL
  AND deadline < datetime('now')
ORDER BY deadline ASC;
```

### Core Loop Queries

```sql
-- Tasks with feedback scores
SELECT id, title, feedback_quality, feedback_timeliness
FROM tasks
WHERE feedback_quality IS NOT NULL
ORDER BY feedback_quality DESC;

-- Average feedback by assignee
SELECT 
    assignee,
    AVG(feedback_quality) as avg_quality,
    AVG(feedback_timeliness) as avg_timeliness,
    COUNT(*) as task_count
FROM tasks
WHERE feedback_quality IS NOT NULL
GROUP BY assignee;

-- Time estimation accuracy
SELECT 
    id, title,
    estimated_hours,
    actual_hours,
    CASE 
        WHEN estimated_hours > 0 THEN 
            (1.0 - ABS(actual_hours - estimated_hours) / estimated_hours) * 100
        ELSE NULL 
    END as accuracy_percent
FROM tasks
WHERE estimated_hours IS NOT NULL 
  AND actual_hours IS NOT NULL;
```

### Dependency Queries

```sql
-- Find blocked tasks (have unfinished dependencies)
SELECT t.id, t.title, t.status
FROM tasks t
JOIN dependencies d ON t.id = d.task_id
JOIN tasks dep ON d.depends_on = dep.id
WHERE t.status = 'blocked'
  AND dep.status != 'completed';

-- Dependency tree for a task
WITH RECURSIVE task_tree AS (
    SELECT id, title, 0 as level
    FROM tasks 
    WHERE id = 'target_task_id'
    
    UNION ALL
    
    SELECT t.id, t.title, tt.level + 1
    FROM tasks t
    JOIN dependencies d ON t.id = d.depends_on
    JOIN task_tree tt ON d.task_id = tt.id
)
SELECT * FROM task_tree ORDER BY level, title;
```

### Metrics Queries

```sql
-- Success criteria validation rates
SELECT 
    json_array_length(success_criteria) as criteria_count,
    COUNT(*) as tasks_with_count,
    AVG(feedback_quality) as avg_quality
FROM tasks
WHERE success_criteria IS NOT NULL
GROUP BY criteria_count;

-- Monthly completion trends
SELECT 
    strftime('%Y-%m', completed_at) as month,
    COUNT(*) as completed_tasks,
    AVG(feedback_quality) as avg_quality,
    AVG(actual_hours) as avg_hours
FROM tasks
WHERE completed_at IS NOT NULL
GROUP BY month
ORDER BY month DESC;
```

## Database Maintenance

### Regular Maintenance

```sql
-- Optimize database (run weekly)
VACUUM;
ANALYZE;

-- Check database integrity
PRAGMA integrity_check;

-- View database statistics
SELECT 
    name,
    type,
    count(*) as records
FROM (
    SELECT 'tasks' as name, 'table' as type FROM tasks
    UNION ALL
    SELECT 'dependencies', 'table' FROM dependencies
    UNION ALL
    SELECT 'notifications', 'table' FROM notifications
    UNION ALL
    SELECT 'participants', 'table' FROM participants
);
```

### Backup Strategy

```bash
# Full database backup
cp ~/.task-orchestrator/tasks.db ~/backups/tasks_$(date +%Y%m%d).db

# Export to SQL
sqlite3 ~/.task-orchestrator/tasks.db .dump > backup.sql

# Compressed backup
sqlite3 ~/.task-orchestrator/tasks.db .dump | gzip > backup.sql.gz
```

## Troubleshooting

### Common Issues

**Database locked errors:**
```sql
-- Check for active connections
PRAGMA database_list;

-- Check WAL file size
.mode csv
.output wal_info.csv
PRAGMA wal_checkpoint(FULL);
```

**Performance issues:**
```sql
-- Query plan analysis
EXPLAIN QUERY PLAN 
SELECT * FROM tasks WHERE status = 'pending';

-- Index usage analysis
.expert
SELECT * FROM tasks WHERE status = 'pending' AND assignee = 'agent_123';
```

---

## See Also

- [API Reference](../api/core-loop-api-reference.md)
- [Migration Guide](../../migration/v2.3-migration-guide.md)
- [Performance Guide](../performance/performance-guide.md)
- [Troubleshooting](../../guides/troubleshooting.md)