# Task Orchestrator API Reference

Complete reference documentation for all public APIs and CLI commands in Task Orchestrator v2.3.0.

## Table of Contents

- [CLI Commands](#cli-commands)
- [TaskManager Python API](#taskmanager-python-api)
- [Data Models](#data-models)
- [Environment Variables](#environment-variables)
- [Exit Codes](#exit-codes)

## CLI Commands

### Core Task Management

#### `tm init`
Initialize the task management system and database.

```bash
tm init
```

**Returns**: Success message or error
**Creates**: `~/.task-orchestrator/` directory structure

---

#### `tm add`
Create a new task with optional parameters.

```bash
tm add "Task title" [options]
```

**Options**:
- `--description, -d`: Task description
- `--priority, -p`: Priority level (low/medium/high/critical)
- `--depends-on`: Comma-separated list of dependency task IDs
- `--assignee, -a`: Assign to specific agent
- `--deadline`: ISO 8601 deadline
- `--estimated-hours`: Estimated effort in hours
- `--criteria`: Success criteria in JSON format

**Returns**: Task ID (8 characters)

**Example**:
```bash
tm add "Implement OAuth2" --priority high --deadline "2025-02-01T00:00:00Z" \
  --criteria '[{"criterion":"Tests pass","measurable":"coverage > 80%"}]'
# Output: abc12345
```

---

#### `tm list`
List tasks with optional filtering.

```bash
tm list [options]
```

**Options**:
- `--status, -s`: Filter by status (pending/in_progress/completed/blocked)
- `--assignee, -a`: Filter by assignee
- `--priority, -p`: Filter by priority
- `--has-deps`: Show only tasks with dependencies
- `--format, -f`: Output format (table/json/markdown)

**Example**:
```bash
tm list --status pending --priority high
```

---

#### `tm show`
Display detailed information about a specific task.

```bash
tm show <task_id>
```

**Returns**: Complete task details including dependencies, participants, and context

**Example**:
```bash
tm show abc12345
```

---

#### `tm update`
Update task status or assignment.

```bash
tm update <task_id> [options]
```

**Options**:
- `--status, -s`: New status (pending/in_progress/completed/blocked)
- `--assignee, -a`: New assignee
- `--priority, -p`: New priority

**Example**:
```bash
tm update abc12345 --status in_progress --assignee backend_dev
```

---

#### `tm complete`
Mark a task as completed with optional summary.

```bash
tm complete <task_id> [options]
```

**Options**:
- `--summary`: Completion summary
- `--actual-hours`: Actual hours spent
- `--validate`: Run validation checks

**Example**:
```bash
tm complete abc12345 --summary "Implemented with JWT tokens" --actual-hours 6.5
```

---

#### `tm delete`
Delete a task (checks for dependencies first).

```bash
tm delete <task_id>
```

**Returns**: Success message or dependency error

---

### Core Loop v2.3 Features

#### `tm feedback`
Provide quality feedback on completed tasks.

```bash
tm feedback <task_id> [options]
```

**Options**:
- `--quality, -q`: Quality rating (1-5)
- `--timeliness, -t`: Timeliness rating (1-5)
- `--notes, -n`: Feedback notes

**Example**:
```bash
tm feedback abc12345 --quality 5 --timeliness 4 --notes "Excellent implementation"
```

---

#### `tm progress`
Update task progress with a message.

```bash
tm progress <task_id> <message>
```

**Example**:
```bash
tm progress abc12345 "API endpoints implemented, starting tests"
```

---

#### `tm metrics`
Display task metrics and performance statistics.

```bash
tm metrics [options]
```

**Options**:
- `--period`: Time period (week/month/quarter)
- `--agent`: Filter by specific agent

---

### Collaboration Features

#### `tm join`
Join a task as a participant.

```bash
tm join <task_id> [--role "Description of role"]
```

**Example**:
```bash
tm join abc12345 --role "Frontend implementation"
```

---

#### `tm share`
Share context visible to all task participants.

```bash
tm share <task_id> <content> [--type update|discovery|decision]
```

**Example**:
```bash
tm share abc12345 "API endpoints ready at /api/v1/*" --type update
```

---

#### `tm note`
Add private notes for a task (only visible to you).

```bash
tm note <task_id> <content>
```

**Example**:
```bash
tm note abc12345 "Consider caching strategy for performance"
```

---

#### `tm context`
View all shared context for a task.

```bash
tm context <task_id>
```

**Returns**: YAML-formatted shared context including all contributions

---

#### `tm sync`
Synchronize task state at a checkpoint.

```bash
tm sync <task_id> <checkpoint_name>
```

**Example**:
```bash
tm sync abc12345 "backend_complete"
```

---

### Monitoring & Export

#### `tm watch`
Monitor task notifications and state changes.

```bash
tm watch [--limit 10]
```

**Options**:
- `--limit, -l`: Number of notifications to show

**Returns**: Real-time notifications for task events

---

#### `tm export`
Export tasks in various formats.

```bash
tm export [options]
```

**Options**:
- `--format, -f`: Export format (json/markdown/csv)
- `--status`: Filter by status
- `--output, -o`: Output file path

**Example**:
```bash
tm export --format markdown --status completed --output completed_tasks.md
```

---

### Configuration & Migration

#### `tm config`
Manage configuration settings.

```bash
tm config [options]
```

**Options**:
- `--show`: Display current configuration
- `--set`: Set configuration value
- `--reset`: Reset to defaults

**Example**:
```bash
tm config --set notifications.enabled true
```

---

#### `tm migrate`
Manage database migrations.

```bash
tm migrate [options]
```

**Options**:
- `--status`: Show migration status
- `--apply`: Apply pending migrations
- `--rollback`: Rollback last migration

**Example**:
```bash
tm migrate --status
tm migrate --apply
```

---

## TaskManager Python API

### Import

```python
from tm_production import TaskManager
```

### Constructor

```python
tm = TaskManager()
```

**Attributes**:
- `agent_id`: Unique agent identifier
- `db_path`: Database file path
- `repo_root`: Repository root directory

### Core Methods

#### add()
```python
def add(self, title: str, description: str = None, 
        priority: str = "medium", depends_on: List[str] = None,
        assignee: str = None, deadline: str = None,
        estimated_hours: float = None, 
        success_criteria: List[Dict] = None) -> str
```

Create a new task.

**Returns**: Task ID (8 characters)

---

#### list()
```python
def list(self, status: str = None, assignee: str = None, 
         has_deps: bool = False) -> List[Dict]
```

List tasks with optional filtering.

**Returns**: List of task dictionaries

---

#### show()
```python
def show(self, task_id: str) -> Optional[Dict]
```

Get detailed task information.

**Returns**: Task dictionary or None if not found

---

#### update()
```python
def update(self, task_id: str, status: str = None, 
          assignee: str = None) -> bool
```

Update task status or assignment.

**Returns**: True if successful

---

#### complete()
```python
def complete(self, task_id: str, completion_summary: str = None,
            actual_hours: float = None, validate: bool = False) -> bool
```

Mark task as completed.

**Returns**: True if successful

---

#### delete()
```python
def delete(self, task_id: str) -> bool
```

Delete a task (checks dependencies).

**Returns**: True if successful

---

### Core Loop Methods

#### feedback()
```python
def feedback(self, task_id: str, quality: int = None,
            timeliness: int = None, notes: str = None) -> bool
```

Provide task feedback.

**Parameters**:
- `quality`: Rating 1-5
- `timeliness`: Rating 1-5
- `notes`: Feedback text

---

#### progress()
```python
def progress(self, task_id: str, update: str) -> bool
```

Update task progress.

**Returns**: True if successful

---

### Collaboration Methods

#### join()
```python
def join(self, task_id: str) -> bool
```

Join a task as participant.

---

#### share()
```python
def share(self, task_id: str, content: str, 
         type: str = "update") -> bool
```

Share context with all participants.

---

#### note()
```python
def note(self, task_id: str, content: str) -> bool
```

Add private notes to task.

---

#### context()
```python
def context(self, task_id: str) -> Dict
```

Get all shared context for task.

---

### Monitoring Methods

#### watch()
```python
def watch(self, limit: int = 10) -> List[Dict]
```

Get recent notifications.

---

#### export()
```python
def export(self, format: str = "json") -> str
```

Export tasks in specified format.

---

## Data Models

### Task Object

```python
{
    "id": "abc12345",                    # 8-character unique ID
    "title": "Task title",               # Required
    "description": "Details",            # Optional
    "status": "pending",                 # pending/in_progress/completed/blocked
    "priority": "medium",                # low/medium/high/critical
    "assignee": "agent_001",            # Agent ID
    "created_at": "2025-01-15T10:00:00Z",
    "updated_at": "2025-01-15T10:00:00Z",
    "completed_at": null,
    
    # Core Loop v2.3 fields
    "success_criteria": [...],          # JSON array
    "feedback_quality": 5,              # 1-5 rating
    "feedback_timeliness": 4,           # 1-5 rating
    "feedback_notes": "Great work",
    "completion_summary": "Details...",
    "deadline": "2025-02-01T00:00:00Z",
    "estimated_hours": 8.0,
    "actual_hours": 6.5,
    
    # Relationships
    "dependencies": ["task_001", "task_002"],
    "participants": ["agent_001", "agent_002"]
}
```

### Success Criteria Format

```json
[
    {
        "criterion": "All tests pass",
        "measurable": "test_coverage > 80%"
    }
]
```

### Notification Object

```json
{
    "id": 1,
    "task_id": "abc12345",
    "event_type": "completed",          # created/started/completed/blocked/unblocked
    "message": "Task completed by agent_001",
    "created_at": "2025-01-15T10:00:00Z",
    "read": false
}
```

## Environment Variables

- `TM_AGENT_ID`: Override auto-generated agent ID
- `TM_DB_PATH`: Custom database path
- `TM_DEBUG`: Enable debug logging (1/0)
- `TM_TEST_MODE`: Enable test mode (1/0)

## Exit Codes

- `0`: Success
- `1`: General error
- `2`: Validation error
- `3`: Database error
- `4`: Dependency error
- `5`: Permission error

---

*Last Updated: 2025-08-21*
*Version: 2.3.0*
*This is the authoritative API reference for Task Orchestrator*