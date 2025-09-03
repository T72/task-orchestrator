# Task Orchestrator API Reference

## Status: Implemented
## Last Verified: August 23, 2025
Against version: v2.6.0

Complete reference documentation for all public APIs, classes, and functions in Task Orchestrator.

## Table of Contents

- [Core Modules](#core-modules)
- [TaskManager Class](#taskmanager-class)
- [Orchestrator Class](#orchestrator-class)
- [Worker Class](#worker-class)
- [Data Models](#data-models)
- [Exceptions](#exceptions)
- [Utility Functions](#utility-functions)
- [CLI Reference](#cli-reference)
- [Integration APIs](#integration-apis)

## Core Modules

### tm (Main CLI Module)

The primary executable providing the command-line interface and core TaskManager implementation.

**Location**: `tm`  
**Purpose**: Main CLI interface and TaskManager implementation  
**Dependencies**: Python 3.8+ standard library only

### tm_orchestrator.py

Orchestrator interface for multi-agent coordination and project management.

**Location**: `tm_orchestrator.py`  
**Purpose**: Agent coordination and project-level task management  
**Dependencies**: Python 3.8+ standard library, YAML support

### tm_production.py

Production-enhanced version with context sharing and advanced features.

**Location**: `tm_production.py`  
**Purpose**: Production deployment with context management  
**Dependencies**: Python 3.8+ standard library

### tm_worker.py

Simplified worker interface for task execution.

**Location**: `tm_worker.py`  
**Purpose**: Simple worker interface for task processing  
**Dependencies**: Python 3.8+ standard library

## TaskManager Class

The core class providing task management functionality.

### Constructor

```python
class TaskManager:
    def __init__(self)
```

**Description**: Initializes TaskManager with database connection and agent identification.

**Attributes**:
- `repo_root` (Path): Git repository root directory
- `db_dir` (Path): Database directory (.task-orchestrator)
- `db_path` (Path): SQLite database file path
- `agent_id` (str): Unique agent identifier
- `max_retries` (int): Maximum retry attempts (default: 3)
- `max_title_length` (int): Maximum task title length (default: 500)
- `max_description_length` (int): Maximum description length (default: 5000)

**Example**:
```python
from tm import TaskManager

tm = TaskManager()
print(f"Agent ID: {tm.agent_id}")
print(f"Database: {tm.db_path}")
```

### Database Operations

#### init_db()

```python
def init_db(self) -> None
```

**Description**: Initialize database schema with all required tables and indexes.

**Raises**:
- `Exception`: If database initialization fails

**Tables Created**:
- `tasks`: Main task storage
- `dependencies`: Task dependency relationships
- `file_refs`: File references and line numbers
- `notifications`: Agent notifications
- `audit_log`: Change tracking

**Example**:
```python
tm = TaskManager()
tm.init_db()
print("Database initialized successfully")
```

### Task Operations

#### add_task()

```python
def add_task(self, title: str, description: str = "", priority: str = "medium",
             depends_on: List[str] = None, file_refs: List[Dict] = None,
             tags: List[str] = None) -> str
```

**Description**: Create a new task with validation and dependency checking.

**Parameters**:
- `title` (str): Task title (required, max 500 characters)
- `description` (str, optional): Detailed description (max 5000 characters)
- `priority` (str, optional): Priority level ("low", "medium", "high", "critical")
- `depends_on` (List[str], optional): List of task IDs this task depends on
- `file_refs` (List[Dict], optional): File references with paths and line numbers
- `tags` (List[str], optional): List of tags for categorization

**Returns**:
- `str`: 8-character task ID if successful, None if failed

**Raises**:
- `ValidationError`: If input validation fails
- `CircularDependencyError`: If dependencies would create a cycle

**File Reference Format**:
```python
file_refs = [
    {
        'file_path': 'src/auth.py',
        'line_start': 42,
        'line_end': 60,
        'context': 'Authentication validation function'
    }
]
```

**Example**:
```python
# Simple task
task_id = tm.add_task("Fix login bug")

# Complex task with dependencies and file references
parent_id = tm.add_task("Refactor authentication system", priority="high")
task_id = tm.add_task(
    title="Update login validation",
    description="Improve password validation with better error messages",
    priority="medium",
    depends_on=[parent_id],
    file_refs=[{
        'file_path': 'src/auth.py',
        'line_start': 42,
        'line_end': 60
    }],
    tags=["authentication", "security"]
)
print(f"Created task: {task_id}")
```

#### update_task()

```python
def update_task(self, task_id: str, status: str = None, assignee: str = None,
                impact_notes: str = None) -> bool
```

**Description**: Update task fields with validation and cascading effects.

**Parameters**:
- `task_id` (str): 8-character task ID
- `status` (str, optional): New status ("pending", "in_progress", "completed", "blocked", "cancelled")
- `assignee` (str, optional): Agent ID to assign task to
- `impact_notes` (str, optional): Notes about the changes or impact

**Returns**:
- `bool`: True if update successful, False otherwise

**Side Effects**:
- Completing a task automatically unblocks dependent tasks
- Status changes trigger notifications
- Updates audit log

**Example**:
```python
# Start working on a task
success = tm.update_task("abc12345", status="in_progress")

# Assign task to another agent
success = tm.update_task("abc12345", assignee="alice_dev")

# Complete task with impact notes
success = tm.update_task(
    "abc12345", 
    status="completed",
    impact_notes="Fixed authentication bug, updated tests"
)
```

#### delete_task()

```python
def delete_task(self, task_id: str) -> bool
```

**Description**: Delete a task after checking for dependent tasks.

**Parameters**:
- `task_id` (str): 8-character task ID

**Returns**:
- `bool`: True if deletion successful, False otherwise

**Validation**:
- Cannot delete tasks that have dependent tasks
- Must be a valid task ID

**Example**:
```python
# Delete task (will fail if other tasks depend on it)
success = tm.delete_task("abc12345")
if not success:
    print("Cannot delete: other tasks depend on this one")
```

#### list_tasks()

```python
def list_tasks(self, status: str = None, assignee: str = None,
               has_deps: bool = False, limit: int = 100) -> List[Dict]
```

**Description**: List tasks with filtering and pagination.

**Parameters**:
- `status` (str, optional): Filter by status
- `assignee` (str, optional): Filter by assigned agent
- `has_deps` (bool, optional): Only show tasks with dependencies
- `limit` (int, optional): Maximum number of tasks to return

**Returns**:
- `List[Dict]`: List of task dictionaries with additional metadata

**Task Dictionary Fields**:
```python
{
    'id': 'abc12345',
    'title': 'Fix authentication bug',
    'description': 'Detailed description...',
    'status': 'pending',
    'priority': 'high',
    'assignee': 'alice_dev',
    'created_at': '2024-01-15T10:30:00',
    'updated_at': '2024-01-15T14:20:00',
    'completed_at': None,
    'created_by': 'bob_dev',
    'tags': ['authentication', 'security'],
    'dependencies': ['def67890'],  # Tasks this depends on
    'blocks': ['ghi11111'],        # Tasks that depend on this
    'file_refs': [...]             # File references
}
```

**Example**:
```python
# List all pending tasks
pending_tasks = tm.list_tasks(status="pending")

# List tasks assigned to specific agent
alice_tasks = tm.list_tasks(assignee="alice_dev", limit=50)

# List only tasks with dependencies
complex_tasks = tm.list_tasks(has_deps=True)

for task in pending_tasks:
    print(f"[{task['id']}] {task['title']} - {task['priority']}")
```

#### show_task()

```python
def show_task(self, task_id: str) -> Dict
```

**Description**: Get detailed information about a specific task.

**Parameters**:
- `task_id` (str): 8-character task ID

**Returns**:
- `Dict`: Complete task information including dependencies, file references, and audit log

**Additional Fields**:
- `file_refs`: Complete file reference information
- `audit_log`: Recent change history (last 5 entries)

**Example**:
```python
task = tm.show_task("abc12345")
if task:
    print(f"Title: {task['title']}")
    print(f"Status: {task['status']}")
    print(f"Dependencies: {task['dependencies']}")
    
    if task['file_refs']:
        print("File References:")
        for ref in task['file_refs']:
            line_info = f":{ref['line_start']}"
            if ref['line_end']:
                line_info += f"-{ref['line_end']}"
            print(f"  {ref['file_path']}{line_info}")
```

#### complete_task()

```python
def complete_task(self, task_id: str, impact_review: bool = False) -> bool
```

**Description**: Mark a task as completed with optional impact analysis.

**Parameters**:
- `task_id` (str): 8-character task ID
- `impact_review` (bool, optional): Perform impact analysis on completion

**Returns**:
- `bool`: True if completion successful, False otherwise

**Side Effects**:
- Automatically unblocks dependent tasks
- Creates notifications for affected agents
- Updates completion timestamp

**Example**:
```python
# Simple completion
success = tm.complete_task("abc12345")

# Completion with impact review
success = tm.complete_task("abc12345", impact_review=True)
```

### Notification Operations

#### check_notifications()

```python
def check_notifications(self) -> List[Dict]
```

**Description**: Check for pending notifications for the current agent.

**Returns**:
- `List[Dict]`: List of notification dictionaries

**Notification Types**:
- `unblocked`: Dependencies completed, task is ready
- `impacted`: Related files changed, review may be needed
- `conflict`: Multiple agents working on same files
- `completed`: Tasks in watch list finished

**Example**:
```python
notifications = tm.check_notifications()
for notif in notifications:
    print(f"[{notif['type']}] {notif['task_title']}")
    print(f"  {notif['message']}")
```

### Export Operations

#### export_tasks()

```python
def export_tasks(self, format: str = "json") -> str
```

**Description**: Export all tasks in specified format.

**Parameters**:
- `format` (str): Export format ("json" or "markdown")

**Returns**:
- `str`: Formatted export data

**JSON Format**: Complete task data as JSON array  
**Markdown Format**: Human-readable report with statistics

**Example**:
```python
# Export as JSON
json_data = tm.export_tasks(format="json")
with open("tasks_backup.json", "w") as f:
    f.write(json_data)

# Export as Markdown report
markdown_report = tm.export_tasks(format="markdown")
with open("project_status.md", "w") as f:
    f.write(markdown_report)
```

### Validation Methods

#### _validate_task_id()

```python
def _validate_task_id(self, task_id: str) -> bool
```

**Description**: Validate task ID format (8-character hexadecimal).

**Parameters**:
- `task_id` (str): Task ID to validate

**Returns**:
- `bool`: True if valid format, False otherwise

#### _validate_title()

```python
def _validate_title(self, title: str) -> str
```

**Description**: Validate and sanitize task title.

**Parameters**:
- `title` (str): Task title to validate

**Returns**:
- `str`: Sanitized title

**Raises**:
- `ValidationError`: If title is empty or too long

#### _validate_status()

```python
def _validate_status(self, status: str) -> str
```

**Description**: Validate task status value.

**Parameters**:
- `status` (str): Status to validate

**Returns**:
- `str`: Validated status

**Raises**:
- `ValidationError`: If status is not in allowed values

**Valid Statuses**: "pending", "in_progress", "completed", "blocked", "cancelled"

#### _validate_priority()

```python
def _validate_priority(self, priority: str) -> str
```

**Description**: Validate task priority value.

**Parameters**:
- `priority` (str): Priority to validate

**Returns**:
- `str`: Validated priority

**Raises**:
- `ValidationError`: If priority is not in allowed values

**Valid Priorities**: "low", "medium", "high", "critical"

## Orchestrator Class

Multi-agent coordination and project management interface.

### Constructor

```python
class Orchestrator:
    def __init__(self, orchestrator_id: str = None)
```

**Description**: Initialize orchestrator for agent coordination.

**Parameters**:
- `orchestrator_id` (str, optional): Unique orchestrator identifier

**Example**:
```python
from tm_orchestrator import Orchestrator

orchestrator = Orchestrator()
print(f"Orchestrator ID: {orchestrator.orchestrator_id}")
```

### Project Management

#### create_project()

```python
def create_project(self, name: str, description: str = "") -> str
```

**Description**: Create a new project workspace for task coordination.

**Parameters**:
- `name` (str): Project name
- `description` (str, optional): Project description

**Returns**:
- `str`: Project ID

**Example**:
```python
project_id = orchestrator.create_project(
    "User Authentication Redesign",
    "Complete overhaul of authentication system"
)
```

#### assign_agents()

```python
def assign_agents(self, project_id: str, agents: List[str]) -> bool
```

**Description**: Assign agents to a project.

**Parameters**:
- `project_id` (str): Project identifier
- `agents` (List[str]): List of agent IDs

**Returns**:
- `bool`: True if assignment successful

**Example**:
```python
success = orchestrator.assign_agents(
    project_id,
    ["alice_dev", "bob_backend", "charlie_frontend"]
)
```

### Task Coordination

#### coordinate_tasks()

```python
def coordinate_tasks(self, project_id: str) -> Dict
```

**Description**: Coordinate task distribution among assigned agents.

**Parameters**:
- `project_id` (str): Project identifier

**Returns**:
- `Dict`: Coordination status and assignments

**Example**:
```python
coordination = orchestrator.coordinate_tasks(project_id)
print(f"Tasks distributed: {coordination['distributed_count']}")
print(f"Pending assignments: {coordination['pending_count']}")
```

## Worker Class

Simplified interface for task execution and worker processes.

### Constructor

```python
class Worker:
    def __init__(self, worker_id: str = None)
```

**Description**: Initialize worker for task processing.

**Parameters**:
- `worker_id` (str, optional): Unique worker identifier

### Task Processing

#### get_assigned_tasks()

```python
def get_assigned_tasks(self) -> List[Dict]
```

**Description**: Get tasks assigned to this worker.

**Returns**:
- `List[Dict]`: List of assigned tasks

#### start_task()

```python
def start_task(self, task_id: str) -> bool
```

**Description**: Start working on an assigned task.

**Parameters**:
- `task_id` (str): Task identifier

**Returns**:
- `bool`: True if task started successfully

#### complete_task()

```python
def complete_task(self, task_id: str, notes: str = "") -> bool
```

**Description**: Mark task as completed with optional notes.

**Parameters**:
- `task_id` (str): Task identifier
- `notes` (str, optional): Completion notes

**Returns**:
- `bool`: True if completion successful

**Example**:
```python
from tm_worker import Worker

worker = Worker("worker_01")

# Get assigned tasks
tasks = worker.get_assigned_tasks()
for task in tasks:
    if task['priority'] == 'high':
        # Start high priority task
        worker.start_task(task['id'])
        
        # Simulate work completion
        worker.complete_task(
            task['id'], 
            "Implemented feature with unit tests"
        )
```

## Data Models

### Task Model

```python
{
    'id': str,              # 8-character hex ID
    'title': str,           # Task title (max 500 chars)
    'description': str,     # Optional description (max 5000 chars)
    'status': str,          # pending|in_progress|completed|blocked|cancelled
    'priority': str,        # low|medium|high|critical
    'assignee': str,        # Agent ID (optional)
    'created_at': str,      # ISO datetime
    'updated_at': str,      # ISO datetime
    'completed_at': str,    # ISO datetime (optional)
    'created_by': str,      # Agent ID
    'impact_notes': str,    # Optional impact notes
    'tags': List[str],      # List of tags
    'version': int,         # Optimistic locking version
    'dependencies': List[str],  # Task IDs this depends on
    'blocks': List[str],        # Task IDs that depend on this
    'file_refs': List[Dict]     # File references
}
```

### File Reference Model

```python
{
    'id': int,              # Reference ID
    'task_id': str,         # Associated task ID
    'file_path': str,       # Relative file path
    'line_start': int,      # Starting line number (optional)
    'line_end': int,        # Ending line number (optional)
    'context': str          # Optional context description
}
```

### Notification Model

```python
{
    'id': str,              # Notification ID
    'task_id': str,         # Associated task ID
    'type': str,            # blocked|unblocked|completed|impacted|conflict
    'target_agent': str,    # Target agent ID (optional)
    'message': str,         # Notification message
    'created_at': str,      # ISO datetime
    'acknowledged': bool,   # Whether notification was read
    'task_title': str       # Associated task title
}
```

### Audit Log Model

```python
{
    'id': int,              # Log entry ID
    'task_id': str,         # Associated task ID
    'action': str,          # created|updated|deleted|completed
    'old_value': str,       # JSON of old values (optional)
    'new_value': str,       # JSON of new values (optional)
    'changed_by': str,      # Agent ID who made change
    'changed_at': str       # ISO datetime
}
```

## v2.6.0 Feature Classes

### TemplateParser Class

Parses and validates task templates in YAML or JSON format.

**Location**: `src/template_parser.py`  
**Purpose**: Parse task templates with variable definitions and validation  
**Dependencies**: Python 3.8+ standard library, YAML support

#### Methods

##### parse_template()

```python
def parse_template(self, template_path: str) -> Dict[str, Any]
```

**Description**: Parse a template file and validate its structure.

**Parameters**:
- `template_path` (str): Path to template file (YAML or JSON)

**Returns**:
- `Dict[str, Any]`: Parsed template structure with metadata, variables, and tasks

**Example**:
```python
parser = TemplateParser()
template = parser.parse_template(".task-orchestrator/templates/bug-fix.yaml")
print(f"Template: {template['metadata']['name']}")
```

### TemplateInstantiator Class

Instantiates templates with variable substitution and expression evaluation.

**Location**: `src/template_instantiator.py`  
**Purpose**: Create tasks from templates with variable replacement  
**Dependencies**: Python 3.8+ standard library

#### Methods

##### instantiate()

```python
def instantiate(self, template: Dict[str, Any], variables: Dict[str, Any]) -> List[Dict[str, Any]]
```

**Description**: Instantiate a template with provided variables.

**Parameters**:
- `template` (Dict): Parsed template structure
- `variables` (Dict): Variable values for substitution

**Returns**:
- `List[Dict]`: List of task definitions ready for creation

**Example**:
```python
instantiator = TemplateInstantiator()
tasks = instantiator.instantiate(template, {
    "severity": "critical",
    "component": "auth",
    "issue_id": "BUG-123"
})
```

### InteractiveWizard Class

Interactive wizard for guided task creation with multiple modes.

**Location**: `src/interactive_wizard.py`  
**Purpose**: Provide interactive task creation experience  
**Dependencies**: Python 3.8+ standard library

#### Methods

##### run()

```python
def run(self) -> bool
```

**Description**: Launch interactive wizard with full menu options.

**Returns**:
- `bool`: True if tasks created successfully, False otherwise

##### quick_start()

```python
def quick_start(self) -> bool
```

**Description**: Quick mode with streamlined prompts for rapid task creation.

**Returns**:
- `bool`: True if tasks created successfully, False otherwise

**Example**:
```python
wizard = InteractiveWizard(parser, instantiator, tm)
# Full interactive mode
success = wizard.run()
# Quick mode
success = wizard.quick_start()
```

### HookPerformanceMonitor Class

Monitors and tracks hook execution performance with alerts and reporting.

**Location**: `src/hook_performance_monitor.py`  
**Purpose**: Track hook performance metrics and generate alerts  
**Dependencies**: Python 3.8+ standard library, SQLite

#### Methods

##### execute_hook_with_monitoring()

```python
def execute_hook_with_monitoring(self, hook_path: str, hook_type: str, 
                                context: Dict[str, Any]) -> Tuple[bool, float]
```

**Description**: Execute a hook while tracking performance metrics.

**Parameters**:
- `hook_path` (str): Path to hook script
- `hook_type` (str): Type of hook (pre_add, post_complete, etc.)
- `context` (Dict): Context data for hook execution

**Returns**:
- `Tuple[bool, float]`: (Success status, Execution time in milliseconds)

##### generate_report()

```python
def generate_report(self, hook_name: Optional[str] = None, 
                   days: int = 7) -> str
```

**Description**: Generate performance report for hooks.

**Parameters**:
- `hook_name` (str, optional): Specific hook to report on
- `days` (int): Number of days to analyze

**Returns**:
- `str`: Formatted performance report with statistics

##### check_alerts()

```python
def check_alerts(self, severity: Optional[str] = None, 
                hours: int = 24) -> List[Dict[str, Any]]
```

**Description**: Check for performance alerts.

**Parameters**:
- `severity` (str, optional): Filter by severity (warning, critical)
- `hours` (int): Hours to look back

**Returns**:
- `List[Dict]`: List of alerts with details

**Example**:
```python
monitor = HookPerformanceMonitor()
success, exec_time = monitor.execute_hook_with_monitoring(
    ".task-orchestrator/hooks/pre_add.sh",
    "pre_add",
    {"task_title": "Fix bug"}
)
print(f"Hook executed in {exec_time}ms")

# Generate report
report = monitor.generate_report(days=30)
print(report)
```

## Exceptions

### ValidationError

```python
class ValidationError(Exception):
    """Raised when input validation fails"""
    pass
```

**Usage**:
```python
try:
    tm.add_task("")  # Empty title
except ValidationError as e:
    print(f"Validation failed: {e}")
```

### CircularDependencyError

```python
class CircularDependencyError(Exception):
    """Raised when a circular dependency is detected"""
    pass
```

**Usage**:
```python
try:
    tm.add_task("Task B", depends_on=["task_a_id"])
    # If task_a depends on task_b, this would raise CircularDependencyError
except CircularDependencyError as e:
    print(f"Circular dependency detected: {e}")
```

## Utility Functions

### Status and Priority Enums

```python
class TaskStatus(Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    BLOCKED = "blocked"
    CANCELLED = "cancelled"

class Priority(Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class NotificationType(Enum):
    BLOCKED = "blocked"
    UNBLOCKED = "unblocked"
    COMPLETED = "completed"
    IMPACTED = "impacted"
    CONFLICT = "conflict"
```

### Helper Functions

#### _find_repo_root()

```python
def _find_repo_root() -> Path
```

**Description**: Find the git repository root directory.

**Returns**:
- `Path`: Repository root path, or current directory if not in git repo

#### _get_agent_id()

```python
def _get_agent_id() -> str
```

**Description**: Generate unique agent identifier.

**Returns**:
- `str`: 8-character agent ID based on process and user

## Database Migration

### Migration System (v2.6.0+)

Task Orchestrator includes automatic database migration to handle schema changes between versions.

#### Automatic Migration

Migrations are applied automatically when:
- Running any command with an older database schema
- The system detects missing columns (e.g., `created_by` field)

#### Manual Migration Commands

```bash
# Check migration status
tm migrate --status

# Apply pending migrations
tm migrate --apply

# Rollback last migration (if supported)
tm migrate --rollback
```

#### Migration for v2.6.0

The v2.6.0 migration adds multi-agent support:
- Adds `created_by` field (TEXT NOT NULL DEFAULT 'user')
- Tracks which agent created each task
- Automatic backfill for existing tasks

**Example Migration Output**:
```
Backup created: ~/.task-orchestrator/backups/tasks_backup_20250822.db
Applying migration: Add created_by field for multi-agent support...
✓ Migration applied successfully
Database schema updated to v2.6.0
```

## CLI Reference

### Command Structure

```bash
./tm <command> [arguments] [options]
```

### Commands

#### init

Initialize the task manager database.

```bash
./tm init
```

**Description**: Creates database and required tables  
**Returns**: Success message or error

#### add

Add a new task.

```bash
./tm add "Task title" [options]
```

**Options**:
- `-d, --description TEXT`: Task description
- `-p, --priority {low,medium,high,critical}`: Priority level
- `--depends-on TASK_ID [TASK_ID ...]`: Dependencies
- `--file PATH[:LINE[:END]]`: File references
- `--tag TAG`: Tags (can be used multiple times)

**Examples**:
```bash
./tm add "Fix login bug" --priority high
./tm add "Refactor auth" --file src/auth.py:42:60 --tag refactor
./tm add "Integration tests" --depends-on abc12345 def67890
```

#### list

List tasks with optional filtering.

```bash
./tm list [options]
```

**Options**:
- `--status {pending,in_progress,completed,blocked,cancelled}`: Filter by status
- `--assignee AGENT_ID`: Filter by assignee
- `--has-deps`: Only show tasks with dependencies
- `--limit N`: Maximum number of tasks

**Examples**:
```bash
./tm list --status pending --limit 20
./tm list --assignee alice_dev
./tm list --has-deps
```

#### show

Show detailed task information.

```bash
./tm show TASK_ID
```

**Example**:
```bash
./tm show abc12345
```

#### update

Update task properties.

```bash
./tm update TASK_ID [options]
```

**Options**:
- `--status {pending,in_progress,completed,blocked,cancelled}`: New status
- `--assignee AGENT_ID`: Assign to agent
- `--impact TEXT`: Impact notes

**Examples**:
```bash
./tm update abc12345 --status in_progress
./tm update abc12345 --assignee alice_dev
./tm update abc12345 --impact "Fixed core issue, testing remaining"
```

#### complete

Mark task as completed.

```bash
./tm complete TASK_ID [options]
```

**Options**:
- `--impact-review`: Perform impact analysis

**Example**:
```bash
./tm complete abc12345 --impact-review
```

#### delete

Delete a task.

```bash
./tm delete TASK_ID [options]
```

**Options**:
- `--force`: Force deletion (reserved for future use)

**Example**:
```bash
./tm delete abc12345
```

#### assign

Assign task to an agent.

```bash
./tm assign TASK_ID AGENT_ID
```

**Example**:
```bash
./tm assign abc12345 alice_dev
```

#### watch

Check for notifications.

```bash
./tm watch
```

**Output**: List of pending notifications for current agent

#### export

Export tasks in specified format.

```bash
./tm export [options]
```

**Options**:
- `--format {json,markdown}`: Export format (default: json)

**Examples**:
```bash
./tm export --format json > backup.json
./tm export --format markdown > report.md
```

## Integration APIs

### Environment Variables

```bash
# Agent identification
export TM_AGENT_ID="custom_agent_id"

# Database location
export TM_DB_PATH="/custom/path/tasks.db"

# Lock timeout (seconds)
export TM_LOCK_TIMEOUT=30

# Verbose logging
export TM_VERBOSE=1

# Claude Code integration
export TM_CLAUDE_INTEGRATION=true
```

### Python Integration

```python
#!/usr/bin/env python3
"""Example Python integration"""

import sys
import os

# Add tm to path
sys.path.insert(0, '/path/to/task-orchestrator')

from tm import TaskManager, ValidationError

def create_tasks_from_issues(issues):
    """Create tasks from external issue tracker"""
    tm = TaskManager()
    
    for issue in issues:
        try:
            task_id = tm.add_task(
                title=issue['title'],
                description=issue['description'],
                priority=issue['priority'],
                tags=issue['labels']
            )
            print(f"Created task {task_id} for issue {issue['id']}")
        except ValidationError as e:
            print(f"Failed to create task for issue {issue['id']}: {e}")

def sync_task_status(external_id, new_status):
    """Sync task status with external system"""
    tm = TaskManager()
    
    # Find task by external reference
    tasks = tm.list_tasks()
    for task in tasks:
        if external_id in task.get('description', ''):
            tm.update_task(task['id'], status=new_status)
            break
```

### Shell Integration

```bash
#!/bin/bash
# Example shell integration

# Source tm functions
TM_PATH="/path/to/task-orchestrator"

# Helper functions
tm_create_from_commit() {
    local commit_msg="$1"
    local files_changed="$2"
    
    # Create task from commit
    local task_id=$(${TM_PATH}/tm add "$commit_msg" --tag commit)
    
    # Add file references
    for file in $files_changed; do
        ${TM_PATH}/tm add "Review changes in $file" \
            --depends-on "$task_id" \
            --file "$file" \
            --tag review
    done
}

# Git hook integration
tm_post_commit_hook() {
    local commit_hash=$(git rev-parse HEAD)
    local commit_msg=$(git log -1 --pretty=%s)
    local files=$(git diff-tree --no-commit-id --name-only -r HEAD)
    
    tm_create_from_commit "$commit_msg" "$files"
}
```

### Claude Code Integration

```python
# Claude Code plugin example
class TaskOrchestratorPlugin:
    def __init__(self):
        self.tm = TaskManager()
    
    def on_file_change(self, file_path, changes):
        """Called when Claude Code modifies a file"""
        # Find related tasks
        tasks = self.tm.list_tasks()
        related_tasks = []
        
        for task in tasks:
            for ref in task.get('file_refs', []):
                if ref['file_path'] == file_path:
                    related_tasks.append(task)
        
        # Notify relevant agents
        for task in related_tasks:
            if task['assignee']:
                self.tm._create_notification(
                    conn=None,  # Handle connection properly
                    task_id=task['id'],
                    notif_type=NotificationType.IMPACTED,
                    message=f"File {file_path} modified",
                    target_agent=task['assignee']
                )
    
    def suggest_tasks(self, code_analysis):
        """Suggest tasks based on code analysis"""
        suggestions = []
        
        if code_analysis['has_todos']:
            for todo in code_analysis['todos']:
                suggestions.append({
                    'title': f"TODO: {todo['text']}",
                    'file_ref': {
                        'file_path': todo['file'],
                        'line_start': todo['line']
                    },
                    'priority': 'medium',
                    'tags': ['todo', 'code-analysis']
                })
        
        return suggestions
```

This comprehensive API reference provides complete documentation for all public interfaces in Task Orchestrator. For additional examples and integration patterns, see the [User Guide](USER_GUIDE.md) and [Developer Guide](DEVELOPER_GUIDE.md).