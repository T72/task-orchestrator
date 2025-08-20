# Database Schema Documentation

**Generated**: 2025-08-20 14:06:17
**Source**: `src/tm_production.py`

> **Note**: This documentation is auto-generated from code comments. Do not edit directly.

## Tables

### Quick Navigation

- [tasks](#tasks-table)
- [dependencies](#dependencies-table)
- [notifications](#notifications-table)
- [participants](#participants-table)

## tasks Table

**Purpose**: Core task storage table. Tracks all tasks with status, priority, and assignment.

### Structure

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT PRIMARY KEY | 8-character unique identifier, auto-generated |
| `title` | TEXT NOT NULL | Task title/description (required, max 500 chars recommended) |
| `description` | TEXT | Extended task details (optional) |
| `status` | TEXT DEFAULT 'pending' | Task status - Values: pending\|in_progress\|completed\|blocked\|cancelled |
| `priority` | TEXT DEFAULT 'medium' | Task priority - Values: low\|medium\|high\|critical |
| `assignee` | TEXT | Agent ID or username assigned to task (optional) |
| `created_at` | TEXT NOT NULL | ISO 8601 timestamp when task was created |
| `updated_at` | TEXT NOT NULL | ISO 8601 timestamp of last modification |
| `completed_at` | TEXT | ISO 8601 timestamp when task was completed (NULL if not completed) |

### SQL Definition

```sql
CREATE TABLE IF NOT EXISTS tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'pending',
    priority TEXT DEFAULT 'medium',
    assignee TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    completed_at TEXT
)
```

## dependencies Table

**Purpose**: Defines task dependencies for workflow management. Tasks block until dependencies complete.

### Structure

| Column | Type | Description |
|--------|------|-------------|
| `task_id` | TEXT NOT NULL | Task that has the dependency (must exist in tasks table) |
| `depends_on` | TEXT NOT NULL | Task that must complete first (must exist in tasks table) |
| `PRIMARY KEY (task_id, depends_on)` | CONSTRAINT | Composite primary key |

### Constraints

- No circular dependencies allowed (enforced in application logic)

### SQL Definition

```sql
CREATE TABLE IF NOT EXISTS dependencies (
    task_id TEXT NOT NULL,
    depends_on TEXT NOT NULL,
    PRIMARY KEY (task_id, depends_on)
)
```

## notifications Table

**Purpose**: Stores notifications for agents about task state changes and important events.

### Structure

| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | Unique notification ID, auto-incremented |
| `agent_id` | TEXT | Target agent for notification (NULL for broadcast to all) |
| `task_id` | TEXT | Related task ID (references tasks.id) |
| `type` | TEXT NOT NULL | Notification type - Values: task_completed\|task_unblocked\|task_assigned\|discovery\|critical |
| `message` | TEXT NOT NULL | Human-readable notification message |
| `created_at` | TEXT NOT NULL | ISO 8601 timestamp when notification was created |
| `read` | BOOLEAN DEFAULT 0 | Read status - 0=unread, 1=read |

### SQL Definition

```sql
CREATE TABLE IF NOT EXISTS notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT,
    task_id TEXT,
    type TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TEXT NOT NULL,
    read BOOLEAN DEFAULT 0
)
```

## participants Table

**Purpose**: Tracks which agents are actively participating in each task for coordination.

### Structure

| Column | Type | Description |
|--------|------|-------------|
| `task_id` | TEXT NOT NULL | Task ID that agent is participating in (references tasks.id) |
| `agent_id` | TEXT NOT NULL | Agent identifier (from TM_AGENT_ID env var or auto-generated) |
| `joined_at` | TEXT NOT NULL | ISO 8601 timestamp when agent joined the task |
| `PRIMARY KEY (task_id, agent_id)` | CONSTRAINT | Composite primary key |

### SQL Definition

```sql
CREATE TABLE IF NOT EXISTS participants (
    task_id TEXT NOT NULL,
    agent_id TEXT NOT NULL,
    joined_at TEXT NOT NULL,
    PRIMARY KEY (task_id, agent_id)
)
```

## Implementation Notes

### Current Implementation Status

- ✅ All tables shown above are implemented
- ✅ Column definitions match source code
- ⚠️ Foreign key constraints not enforced at database level
- ⚠️ Indexes not yet implemented for performance optimization

### Data Storage Patterns

- **Timestamps**: All timestamps use ISO 8601 format
- **IDs**: Task IDs are 8-character strings, auto-generated
- **Agent IDs**: From `TM_AGENT_ID` environment variable or auto-generated

### Related Files

- **Context Storage**: `.task-orchestrator/contexts/{task_id}.yaml`
- **Private Notes**: `.task-orchestrator/private_notes/{task_id}.yaml`
- **Database Location**: `.task-orchestrator/tasks.db`

