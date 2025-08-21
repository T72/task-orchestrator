# Task Orchestrator Database Schema

## Single Source of Truth
This document is the permanent, authoritative reference for Task Orchestrator's database schema and storage architecture. It represents the current state of the database and is updated with each release.

## Storage Architecture

Task Orchestrator uses a **hybrid storage model**:
- **SQLite Database**: Structured data (tasks, dependencies, notifications, participants)
- **File-Based Storage**: Flexible content (shared context, private notes, progress logs)

## SQLite Database Schema

### 1. Tasks Table
The core table containing all task data including Core Loop v2.3 features.

```sql
CREATE TABLE tasks (
    -- Core Fields
    id TEXT PRIMARY KEY,                    -- 8-character unique ID
    title TEXT NOT NULL,                    -- Task title
    description TEXT,                       -- Task description
    status TEXT DEFAULT 'pending',         -- pending, in_progress, completed, blocked
    priority TEXT DEFAULT 'medium',        -- low, medium, high, critical
    assignee TEXT,                          -- Agent ID assigned to task
    created_at TEXT NOT NULL,              -- ISO 8601 timestamp
    updated_at TEXT NOT NULL,              -- ISO 8601 timestamp
    completed_at TEXT,                     -- ISO 8601 timestamp when completed
    
    -- Core Loop v2.3 Features
    success_criteria TEXT,                 -- JSON array of success criteria
    feedback_quality INTEGER,             -- Quality rating 1-5
    feedback_timeliness INTEGER,           -- Timeliness rating 1-5
    feedback_notes TEXT,                   -- Feedback comments
    completion_summary TEXT,               -- Summary provided on completion
    deadline TEXT,                         -- ISO 8601 deadline
    estimated_hours REAL,                 -- Estimated effort in hours
    actual_hours REAL                      -- Actual effort spent in hours
);

-- Indexes for performance
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_assignee ON tasks(assignee);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_deadline ON tasks(deadline);
```

### 2. Dependencies Table
Manages task dependencies and automatic unblocking.

```sql
CREATE TABLE dependencies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT NOT NULL,                 -- Task that has dependency
    depends_on TEXT NOT NULL,              -- Task it depends on
    created_at TEXT NOT NULL,              -- ISO 8601 timestamp
    
    FOREIGN KEY (task_id) REFERENCES tasks(id),
    FOREIGN KEY (depends_on) REFERENCES tasks(id),
    UNIQUE(task_id, depends_on)           -- Prevent duplicate dependencies
);

-- Index for dependency queries
CREATE INDEX idx_dependencies_task ON dependencies(task_id);
CREATE INDEX idx_dependencies_depends ON dependencies(depends_on);
```

### 3. Notifications Table
Tracks task state changes and events for the watch system.

```sql
CREATE TABLE notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT NOT NULL,                 -- Task that changed
    event_type TEXT NOT NULL,             -- created, started, completed, blocked, unblocked
    message TEXT,                           -- Event description
    created_at TEXT NOT NULL,              -- ISO 8601 timestamp
    read BOOLEAN DEFAULT 0,                -- Read status
    
    FOREIGN KEY (task_id) REFERENCES tasks(id)
);

-- Index for unread notifications
CREATE INDEX idx_notifications_unread ON notifications(read, created_at);
```

### 4. Participants Table
Manages multi-agent collaboration on tasks.

```sql
CREATE TABLE participants (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT NOT NULL,                 -- Task ID
    agent_id TEXT NOT NULL,               -- Agent identifier
    role TEXT,                             -- Agent's role in task
    joined_at TEXT NOT NULL,              -- ISO 8601 timestamp
    
    FOREIGN KEY (task_id) REFERENCES tasks(id),
    UNIQUE(task_id, agent_id)             -- Each agent joins once per task
);

-- Index for participant queries
CREATE INDEX idx_participants_task ON participants(task_id);
CREATE INDEX idx_participants_agent ON participants(agent_id);
```

## File-Based Storage Structure

```
~/.task-orchestrator/
├── tasks.db                              # SQLite database
├── contexts/                             # Shared context storage
│   ├── {task_id}.yaml                   # YAML formatted shared context
│   └── {task_id}_progress.jsonl         # Progress update log
├── notes/                                # Private notes storage
│   └── {task_id}_{agent_id}.md         # Markdown private notes
└── archives/                            # Completed task archives
    └── task_{task_id}_{timestamp}.tar.gz
```

### Shared Context Format (YAML)
```yaml
task_id: "abc12345"
updated_at: "2025-01-15T10:30:00Z"
updated_by: "agent_001"
context:
  requirements:
    - "Must support 1000 concurrent users"
    - "Response time < 200ms"
  decisions:
    - decision: "Use PostgreSQL for data store"
      rationale: "Better concurrency than SQLite"
      made_by: "database_specialist"
      date: "2025-01-14T15:00:00Z"
  artifacts:
    - type: "schema"
      path: "designs/db_schema.sql"
      created_by: "database_specialist"
```

### Progress Updates Format (JSONL)
```json
{"timestamp": "2025-01-15T10:00:00Z", "agent": "backend_dev", "progress": 25, "message": "API endpoints defined"}
{"timestamp": "2025-01-15T11:00:00Z", "agent": "backend_dev", "progress": 50, "message": "Authentication implemented"}
{"timestamp": "2025-01-15T14:00:00Z", "agent": "backend_dev", "progress": 75, "message": "Tests written"}
```

### Private Notes Format (Markdown)
```markdown
# Task Notes: abc12345
## Agent: backend_specialist
## Updated: 2025-01-15T10:30:00Z

### Implementation Approach
Considering rate limiting using token bucket algorithm...

### Issues Encountered
- Connection pooling needs optimization
- Consider caching strategy for frequently accessed data

### Next Steps
- [ ] Implement connection retry logic
- [ ] Add performance monitoring
```

## Field Specifications

### Success Criteria Format
```json
[
  {
    "criterion": "All tests pass",
    "measurable": "test_suite.exit_code == 0"
  },
  {
    "criterion": "Performance target met",
    "measurable": "avg_response_time < 200"
  }
]
```

### Status Values
- `pending` - Task created but not started
- `in_progress` - Task actively being worked on
- `completed` - Task successfully completed
- `blocked` - Task blocked by dependencies or issues

### Priority Values
- `low` - Can be deferred
- `medium` - Normal priority (default)
- `high` - Should be addressed soon
- `critical` - Requires immediate attention

### Feedback Ratings
- `1` - Very Poor
- `2` - Poor
- `3` - Acceptable
- `4` - Good
- `5` - Excellent

## Migration Information

### From v2.2 to v2.3
```sql
-- Add Core Loop fields to existing tasks table
ALTER TABLE tasks ADD COLUMN success_criteria TEXT;
ALTER TABLE tasks ADD COLUMN feedback_quality INTEGER;
ALTER TABLE tasks ADD COLUMN feedback_timeliness INTEGER;
ALTER TABLE tasks ADD COLUMN feedback_notes TEXT;
ALTER TABLE tasks ADD COLUMN completion_summary TEXT;
ALTER TABLE tasks ADD COLUMN deadline TEXT;
ALTER TABLE tasks ADD COLUMN estimated_hours REAL;
ALTER TABLE tasks ADD COLUMN actual_hours REAL;

-- Create participants table for collaboration
CREATE TABLE IF NOT EXISTS participants (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT NOT NULL,
    agent_id TEXT NOT NULL,
    role TEXT,
    joined_at TEXT NOT NULL,
    FOREIGN KEY (task_id) REFERENCES tasks(id),
    UNIQUE(task_id, agent_id)
);
```

## API Usage Examples

### Core Loop Features
```python
# Create task with success criteria
task_id = tm.add(
    "Optimize database queries",
    success_criteria=[
        {"criterion": "Query time < 100ms", "measurable": "true"},
        {"criterion": "All tests pass", "measurable": "true"}
    ],
    deadline="2025-02-01T00:00:00Z",
    estimated_hours=8.0
)

# Provide feedback on completion
tm.complete(
    task_id,
    summary="Implemented query caching and indexing",
    actual_hours=6.5
)

tm.feedback(
    task_id,
    quality=5,
    timeliness=4,
    notes="Excellent optimization, delivered ahead of schedule"
)
```

### Collaboration Features
```python
# Multiple agents join a task
tm.join(task_id, agent_id="frontend_dev", role="UI implementation")
tm.join(task_id, agent_id="qa_tester", role="Testing")

# Share context visible to all participants
tm.share(task_id, "api_endpoints", {
    "login": "/api/v1/auth/login",
    "logout": "/api/v1/auth/logout"
})

# Private notes (only visible to specific agent)
tm.note(task_id, "frontend_dev", "Need to handle loading states")

# Update progress
tm.progress(task_id, 50, "Backend API complete")
```

## Performance Considerations

1. **Indexes**: All foreign keys and frequently queried fields are indexed
2. **File Storage**: Shared contexts stored as files to avoid BLOB performance issues
3. **JSONL Progress**: Append-only format for efficient progress tracking
4. **Archive Strategy**: Completed tasks can be archived to maintain database performance

## Backward Compatibility

All v2.3 additions are optional and nullable, ensuring 100% backward compatibility:
- Existing tasks continue to work without Core Loop fields
- Collaboration features are opt-in
- File-based storage gracefully handles missing files

## Validation Rules

1. **Task IDs**: 8-character alphanumeric strings
2. **Timestamps**: ISO 8601 format required
3. **Priorities**: Must be one of: low, medium, high, critical
4. **Status**: Must be one of: pending, in_progress, completed, blocked
5. **Feedback Ratings**: Integer between 1-5 inclusive
6. **Success Criteria**: Valid JSON array when provided

---

*Last Updated: 2025-08-21*
*Version: 2.3.0*
*This is the authoritative schema reference for Task Orchestrator*