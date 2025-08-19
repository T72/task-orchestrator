# Task Orchestrator Developer Guide

A comprehensive guide for developers who want to contribute to, extend, or understand the Task Orchestrator codebase.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Code Structure](#code-structure)
- [Development Setup](#development-setup)
- [Testing Guidelines](#testing-guidelines)
- [Code Style and Conventions](#code-style-and-conventions)
- [Adding New Features](#adding-new-features)
- [Plugin/Extension System](#pluginextension-system)
- [Performance Considerations](#performance-considerations)
- [Security Considerations](#security-considerations)
- [Contributing Guidelines](#contributing-guidelines)

## Architecture Overview

### System Design Philosophy

Task Orchestrator follows several key architectural principles:

1. **Zero External Dependencies**: Uses only Python standard library
2. **Database-Centric**: SQLite provides ACID compliance and concurrent access
3. **Process-Safe**: File locking prevents data corruption
4. **Modular Design**: Clear separation between CLI, business logic, and data layers
5. **Extension-Friendly**: Plugin architecture for custom functionality

### High-Level Architecture

```
┌─────────────────┬─────────────────┬─────────────────┐
│   CLI Layer     │  Orchestrator   │   Worker API    │
│                 │                 │                 │
│ tm (main CLI)   │ tm_orchestrator │  tm_worker.py   │
│ Argument parsing│ Agent coordination│ Simple interface│
│ User interface  │ Project management│ Task execution  │
└─────────────────┴─────────────────┴─────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────┐
│                Core Business Logic                  │
│                                                     │
│ TaskManager Class (tm, tm_production.py)           │
│ • Task CRUD operations                              │
│ • Dependency management                             │
│ • Status tracking and notifications                │
│ • File reference handling                          │
│ • Agent coordination                               │
└─────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────┐
│                 Data Layer                          │
│                                                     │
│ SQLite Database (.task-orchestrator/tasks.db)      │
│ • ACID compliance                                   │
│ • Foreign key constraints                          │
│ • Concurrent access with locking                   │
│ • Audit trail                                      │
└─────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Purpose | Key Classes/Functions |
|-----------|---------|----------------------|
| `tm` | Main CLI interface | `TaskManager`, `main()` |
| `tm_orchestrator.py` | Agent coordination | `Orchestrator` |
| `tm_production.py` | Production features | `TaskManager` (enhanced) |
| `tm_worker.py` | Simple worker interface | `Worker` |

## Code Structure

### File Organization

```
task-orchestrator/
├── tm                          # Main CLI executable
├── tm_orchestrator.py          # Orchestrator interface
├── tm_production.py            # Production version with context sharing
├── tm_worker.py               # Worker interface
├── test_*.py                  # Test files
├── test_*.sh                  # Shell test scripts
├── docs/                      # Documentation
│   ├── examples/              # Code examples
│   └── specifications/        # Requirements and specs
├── .claude/                   # Claude Code integration
│   └── hooks/                 # Git hooks and automation
└── archive/                   # Legacy implementations
    └── legacy-implementations/
```

### Core Classes

#### TaskManager (tm, tm_production.py)

The main business logic class that handles all task operations.

```python
class TaskManager:
    """Core task management functionality"""
    
    def __init__(self):
        # Database setup and agent identification
        
    def add_task(self, title, description, priority, depends_on, file_refs, tags) -> str:
        # Creates new task with validation
        
    def update_task(self, task_id, status, assignee, impact_notes) -> bool:
        # Updates task with cascading effects
        
    def delete_task(self, task_id) -> bool:
        # Deletes task with dependency checking
        
    def list_tasks(self, status, assignee, has_deps, limit) -> List[Dict]:
        # Lists tasks with filtering
        
    def show_task(self, task_id) -> Dict:
        # Shows detailed task information
```

#### Orchestrator (tm_orchestrator.py)

Handles multi-agent coordination and project-level operations.

```python
class Orchestrator:
    """Interface for orchestrating agents"""
    
    def create_project(self, name, description) -> str:
        # Creates new project workspace
        
    def assign_agents(self, project_id, agents) -> bool:
        # Assigns agents to project
        
    def coordinate_tasks(self, project_id) -> Dict:
        # Coordinates task distribution
```

### Database Schema

#### Core Tables

```sql
-- Main tasks table
CREATE TABLE tasks (
    id TEXT PRIMARY KEY CHECK(length(id) = 8),
    title TEXT NOT NULL CHECK(length(title) > 0 AND length(title) <= 500),
    description TEXT CHECK(length(description) <= 5000),
    status TEXT NOT NULL CHECK(status IN ('pending', 'in_progress', 'completed', 'blocked', 'cancelled')),
    priority TEXT NOT NULL CHECK(priority IN ('low', 'medium', 'high', 'critical')),
    assignee TEXT,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP,
    created_by TEXT NOT NULL,
    impact_notes TEXT,
    tags TEXT,
    version INTEGER DEFAULT 1
);

-- Task dependencies
CREATE TABLE dependencies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT NOT NULL,
    depends_on TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    FOREIGN KEY (depends_on) REFERENCES tasks(id) ON DELETE CASCADE,
    UNIQUE(task_id, depends_on),
    CHECK(task_id != depends_on)
);

-- File references
CREATE TABLE file_refs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT NOT NULL,
    file_path TEXT NOT NULL CHECK(length(file_path) > 0),
    line_start INTEGER CHECK(line_start > 0),
    line_end INTEGER CHECK(line_end >= line_start),
    context TEXT,
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);

-- Notifications
CREATE TABLE notifications (
    id TEXT PRIMARY KEY,
    task_id TEXT NOT NULL,
    type TEXT NOT NULL,
    target_agent TEXT,
    message TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    acknowledged BOOLEAN DEFAULT 0,
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);

-- Audit log
CREATE TABLE audit_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT NOT NULL,
    action TEXT NOT NULL,
    old_value TEXT,
    new_value TEXT,
    changed_by TEXT NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Key Indexes

```sql
CREATE INDEX idx_task_status ON tasks(status);
CREATE INDEX idx_task_assignee ON tasks(assignee);
CREATE INDEX idx_task_priority ON tasks(priority);
CREATE INDEX idx_deps_task ON dependencies(task_id);
CREATE INDEX idx_deps_depends ON dependencies(depends_on);
CREATE INDEX idx_notif_target ON notifications(target_agent, acknowledged);
CREATE INDEX idx_file_refs_task ON file_refs(task_id);
CREATE INDEX idx_audit_task ON audit_log(task_id);
```

## Development Setup

### Prerequisites

```bash
# Required tools
python3 --version  # 3.8+
git --version
sqlite3 --version

# Optional but recommended
python3 -m pip install pytest  # For extended testing
python3 -m pip install black   # For code formatting
python3 -m pip install mypy    # For type checking
```

### Environment Setup

```bash
# 1. Clone and setup
git clone https://github.com/T72/task-orchestrator.git
cd task-orchestrator

# 2. Create development environment
python3 -m venv dev-env
source dev-env/bin/activate  # Linux/macOS
# or: dev-env\Scripts\activate  # Windows

# 3. Install development dependencies (optional)
pip install pytest black mypy pylint

# 4. Make scripts executable
chmod +x tm test_*.sh

# 5. Initialize test database
./tm init

# 6. Run initial tests
./test_tm.sh
```

### Development Tools

#### Code Formatting

```bash
# Format Python code
black *.py

# Check formatting
black --check *.py
```

#### Type Checking

```bash
# Check types
mypy tm tm_orchestrator.py tm_production.py tm_worker.py
```

#### Linting

```bash
# Lint code
pylint tm tm_orchestrator.py tm_production.py tm_worker.py
```

### Development Database

```bash
# Create separate development database
export TM_DB_PATH=".task-orchestrator/dev_tasks.db"
./tm init

# Reset development database
rm .task-orchestrator/dev_tasks.db
./tm init
```

## Testing Guidelines

### Test Structure

The project uses a multi-layered testing approach:

1. **Unit Tests**: `test_validation.py`
2. **Integration Tests**: `test_tm.sh`
3. **Edge Case Tests**: `test_edge_cases.sh`, `test_edge_cases.py`
4. **Stress Tests**: `stress_test.sh`

### Running Tests

#### Full Test Suite

```bash
# Run all tests
make test  # If Makefile exists
# or
./test_tm.sh && ./test_edge_cases.sh && python3 test_validation.py
```

#### Individual Test Categories

```bash
# Basic functionality (must pass 100%)
./test_tm.sh

# Edge cases (currently 86% pass rate)
./test_edge_cases.sh

# Validation and security
python3 test_validation.py

# Performance testing
./stress_test.sh
```

### Writing New Tests

#### Unit Test Example

```python
# test_new_feature.py
import unittest
import tempfile
import os
from pathlib import Path

# Import TaskManager
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tm import TaskManager

class TestNewFeature(unittest.TestCase):
    def setUp(self):
        """Setup test environment"""
        self.test_dir = tempfile.mkdtemp()
        os.chdir(self.test_dir)
        self.tm = TaskManager()
        self.tm.init_db()
    
    def tearDown(self):
        """Cleanup test environment"""
        os.chdir("/")
        shutil.rmtree(self.test_dir)
    
    def test_feature_creation(self):
        """Test new feature functionality"""
        result = self.tm.new_feature("test_input")
        self.assertIsNotNone(result)
        self.assertEqual(result.status, "expected_status")

if __name__ == '__main__':
    unittest.main()
```

#### Integration Test Example

```bash
#!/bin/bash
# test_new_workflow.sh

set -e

echo "Testing new workflow..."

# Setup
./tm init

# Test workflow steps
TASK1=$(./tm add "Step 1" | grep -o '[a-f0-9]\{8\}')
TASK2=$(./tm add "Step 2" --depends-on $TASK1 | grep -o '[a-f0-9]\{8\}')

# Verify dependencies
if ! ./tm show $TASK2 | grep -q "Dependencies: $TASK1"; then
    echo "FAIL: Dependencies not created"
    exit 1
fi

echo "PASS: New workflow test"
```

### Test Requirements

#### New Feature Tests Must Include

1. **Happy Path**: Normal usage scenarios
2. **Error Handling**: Invalid inputs and edge cases
3. **Concurrency**: Multi-agent/multi-process safety
4. **Performance**: Acceptable performance characteristics
5. **Backwards Compatibility**: Existing functionality preserved

#### Test Standards

```bash
# Tests must be:
# 1. Deterministic (no random failures)
# 2. Isolated (no dependencies between tests)
# 3. Fast (< 1 second per test)
# 4. Clear (obvious what they're testing)
# 5. Comprehensive (cover error cases)
```

## Code Style and Conventions

### Python Style Guide

We follow PEP 8 with some project-specific conventions:

#### Naming Conventions

```python
# Classes: PascalCase
class TaskManager:
class DependencyResolver:

# Functions and variables: snake_case
def add_task():
def validate_task_id():
task_id = "abc12345"
current_status = "pending"

# Constants: UPPER_SNAKE_CASE
DEFAULT_PRIORITY = "medium"
MAX_TITLE_LENGTH = 500

# Private methods: leading underscore
def _validate_input():
def _acquire_lock():
```

#### Function Documentation

```python
def add_task(self, title: str, description: str = "", priority: str = "medium",
             depends_on: List[str] = None, file_refs: List[Dict] = None,
             tags: List[str] = None) -> str:
    """Add a new task with validation.
    
    Args:
        title: Task title (required, max 500 chars)
        description: Detailed description (optional, max 5000 chars)
        priority: Task priority (low, medium, high, critical)
        depends_on: List of task IDs this task depends on
        file_refs: List of file references with paths and line numbers
        tags: List of tags for categorization
        
    Returns:
        str: Task ID (8-character hex) if successful, None if failed
        
    Raises:
        ValidationError: If input validation fails
        CircularDependencyError: If dependencies would create a cycle
        
    Example:
        >>> tm = TaskManager()
        >>> task_id = tm.add_task("Fix bug", priority="high")
        >>> print(f"Created task: {task_id}")
    """
```

#### Error Handling

```python
# Use specific exceptions
class ValidationError(Exception):
    """Custom exception for validation errors"""
    pass

class CircularDependencyError(Exception):
    """Custom exception for circular dependencies"""
    pass

# Handle errors appropriately
try:
    result = self.risky_operation()
except SpecificError as e:
    print(f"Expected error: {e}", file=sys.stderr)
    return None
except Exception as e:
    print(f"Unexpected error: {e}", file=sys.stderr)
    raise
```

### SQL Style Guide

```sql
-- Use uppercase for SQL keywords
SELECT id, title, status 
FROM tasks 
WHERE status = 'pending' 
ORDER BY priority DESC, created_at ASC;

-- Indent for readability
CREATE TABLE IF NOT EXISTS tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL
);

-- Use meaningful constraint names
CONSTRAINT chk_valid_status 
CHECK (status IN ('pending', 'in_progress', 'completed', 'blocked', 'cancelled'))
```

### Shell Script Conventions

```bash
#!/bin/bash
# Use strict error handling
set -e
set -u
set -o pipefail

# Use meaningful variable names
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_DB_PATH=".task-orchestrator/test_tasks.db"

# Function naming
test_basic_functionality() {
    echo "Testing basic functionality..."
    # Implementation
}

cleanup_test_environment() {
    echo "Cleaning up..."
    # Implementation
}
```

## Adding New Features

### Feature Development Process

#### 1. Design Phase

```markdown
# Feature Design Template

## Overview
Brief description of the feature and its purpose.

## Requirements
- Functional requirements
- Non-functional requirements (performance, security, etc.)
- Compatibility requirements

## Design
- API changes
- Database schema changes
- User interface changes

## Implementation Plan
- Task breakdown
- Testing strategy
- Documentation updates

## Risks and Mitigation
- Potential issues
- Backward compatibility concerns
- Performance impact
```

#### 2. Implementation Guidelines

```python
# 1. Start with tests (TDD approach)
def test_new_feature():
    """Test the new feature before implementing it"""
    pass

# 2. Implement core functionality
def new_feature_implementation():
    """Implement the feature with proper validation"""
    pass

# 3. Add CLI interface
def add_cli_command():
    """Add command-line interface for the feature"""
    pass

# 4. Update documentation
def update_docs():
    """Update all relevant documentation"""
    pass
```

### Example: Adding a New Field

Let's walk through adding a new "estimated_hours" field to tasks:

#### Step 1: Database Schema Update

```python
# In init_db() method, add to tasks table:
def init_db(self):
    # ... existing code ...
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS tasks (
            -- ... existing fields ...
            estimated_hours INTEGER CHECK(estimated_hours > 0),
            -- ... rest of table ...
        )
    ''')
```

#### Step 2: Update TaskManager Methods

```python
def add_task(self, title: str, description: str = "", priority: str = "medium",
             depends_on: List[str] = None, file_refs: List[Dict] = None,
             tags: List[str] = None, estimated_hours: int = None) -> str:
    """Add estimated_hours parameter"""
    
    # Validation
    if estimated_hours is not None and estimated_hours <= 0:
        raise ValidationError("Estimated hours must be positive")
    
    # ... existing code ...
    
    # Insert with new field
    cursor.execute('''
        INSERT INTO tasks (id, title, description, status, priority, assignee,
                          created_at, updated_at, created_by, tags, estimated_hours)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (task_id, title, description, status, priority, self.agent_id,
          now, now, self.agent_id, json.dumps(tags or []), estimated_hours))
```

#### Step 3: Update CLI Interface

```python
# In main() function, add argument:
parser_add.add_argument('--estimated-hours', type=int, 
                       help='Estimated hours to complete task')

# In command handling:
elif args.command == 'add':
    task_id = tm.add_task(
        args.title,
        description=args.description or "",
        priority=args.priority,
        depends_on=args.depends_on,
        file_refs=file_refs if file_refs else None,
        tags=args.tag,
        estimated_hours=args.estimated_hours  # New parameter
    )
```

#### Step 4: Add Tests

```python
def test_estimated_hours():
    """Test estimated hours functionality"""
    tm = TaskManager()
    tm.init_db()
    
    # Test valid estimated hours
    task_id = tm.add_task("Test task", estimated_hours=4)
    task = tm.show_task(task_id)
    assert task['estimated_hours'] == 4
    
    # Test invalid estimated hours
    with pytest.raises(ValidationError):
        tm.add_task("Invalid task", estimated_hours=-1)
```

#### Step 5: Update Documentation

```markdown
# Update USER_GUIDE.md
## Task Creation
```bash
# Add task with estimated time
./tm add "Implement feature X" --estimated-hours 8
```

# Update API_REFERENCE.md
### add_task()
- estimated_hours (int, optional): Estimated hours to complete
```

### Feature Integration Checklist

Before submitting a new feature:

- [ ] **Functionality**: Core feature works as designed
- [ ] **Tests**: Comprehensive test coverage added
- [ ] **Documentation**: User guide and API docs updated
- [ ] **Backwards Compatibility**: Existing functionality preserved
- [ ] **Performance**: No significant performance regression
- [ ] **Security**: No security vulnerabilities introduced
- [ ] **Error Handling**: Proper error handling and validation
- [ ] **CLI Integration**: Command-line interface updated if needed
- [ ] **Database Migration**: Schema changes handled properly

## Plugin/Extension System

### Plugin Architecture

Task Orchestrator supports extensions through several mechanisms:

#### 1. Hook System

```bash
# Create hooks directory
mkdir -p .task-orchestrator/hooks

# Pre-task hook (runs before task creation)
cat > .task-orchestrator/hooks/pre-task << 'EOF'
#!/bin/bash
# Validate task title format
if [[ ! "$1" =~ ^[A-Z] ]]; then
    echo "Error: Task title must start with uppercase letter"
    exit 1
fi
EOF
chmod +x .task-orchestrator/hooks/pre-task

# Post-completion hook (runs after task completion)
cat > .task-orchestrator/hooks/post-complete << 'EOF'
#!/bin/bash
TASK_ID="$1"
echo "Task $TASK_ID completed at $(date)" >> completion.log
# Send notification, update external systems, etc.
EOF
chmod +x .task-orchestrator/hooks/post-complete
```

#### 2. Custom Commands

```python
# Create custom_commands.py
class CustomCommands:
    def __init__(self, task_manager):
        self.tm = task_manager
    
    def bulk_import(self, csv_file):
        """Import tasks from CSV file"""
        import csv
        with open(csv_file, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                self.tm.add_task(
                    title=row['title'],
                    description=row.get('description', ''),
                    priority=row.get('priority', 'medium')
                )
    
    def time_tracking(self, task_id, hours_worked):
        """Add time tracking to task"""
        # Implementation for time tracking
        pass

# Integration in main CLI
def load_extensions():
    """Load custom extensions"""
    try:
        from custom_commands import CustomCommands
        return CustomCommands(tm)
    except ImportError:
        return None
```

#### 3. External Tool Integration

```bash
# Integration with external project management tools
cat > .task-orchestrator/hooks/sync-jira << 'EOF'
#!/bin/bash
# Sync with JIRA
TASK_ID="$1"
TASK_TITLE="$2"
STATUS="$3"

# Example JIRA API call
curl -X POST "https://your-domain.atlassian.net/rest/api/2/issue" \
  -H "Content-Type: application/json" \
  -d "{
    \"fields\": {
      \"project\": {\"key\": \"PROJECT\"},
      \"summary\": \"$TASK_TITLE\",
      \"description\": \"Task from orchestrator: $TASK_ID\",
      \"issuetype\": {\"name\": \"Task\"}
    }
  }"
EOF
```

### Plugin Development Guidelines

#### Plugin Interface

```python
# plugin_interface.py
from abc import ABC, abstractmethod
from typing import Dict, Any, List

class TaskOrchestratorPlugin(ABC):
    """Base class for Task Orchestrator plugins"""
    
    @abstractmethod
    def name(self) -> str:
        """Return plugin name"""
        pass
    
    @abstractmethod
    def version(self) -> str:
        """Return plugin version"""
        pass
    
    def on_task_created(self, task: Dict[str, Any]) -> None:
        """Called when a task is created"""
        pass
    
    def on_task_updated(self, task_id: str, old_values: Dict, new_values: Dict) -> None:
        """Called when a task is updated"""
        pass
    
    def on_task_completed(self, task: Dict[str, Any]) -> None:
        """Called when a task is completed"""
        pass
    
    def custom_commands(self) -> Dict[str, callable]:
        """Return dictionary of custom commands"""
        return {}
```

#### Example Plugin

```python
# time_tracking_plugin.py
from plugin_interface import TaskOrchestratorPlugin
import json
from datetime import datetime

class TimeTrackingPlugin(TaskOrchestratorPlugin):
    def __init__(self, task_manager):
        self.tm = task_manager
        self.time_log_file = ".task-orchestrator/time_log.json"
    
    def name(self) -> str:
        return "Time Tracking"
    
    def version(self) -> str:
        return "1.0.0"
    
    def on_task_updated(self, task_id: str, old_values: Dict, new_values: Dict) -> None:
        """Track time when status changes"""
        if 'status' in new_values:
            self._log_time_event(task_id, new_values['status'])
    
    def custom_commands(self) -> Dict[str, callable]:
        return {
            'time-log': self.show_time_log,
            'time-report': self.generate_time_report
        }
    
    def _log_time_event(self, task_id: str, status: str):
        """Log time tracking event"""
        event = {
            'task_id': task_id,
            'status': status,
            'timestamp': datetime.now().isoformat()
        }
        
        # Append to time log
        try:
            with open(self.time_log_file, 'r') as f:
                log = json.load(f)
        except FileNotFoundError:
            log = []
        
        log.append(event)
        
        with open(self.time_log_file, 'w') as f:
            json.dump(log, f, indent=2)
    
    def show_time_log(self, task_id: str = None):
        """Show time log for task or all tasks"""
        try:
            with open(self.time_log_file, 'r') as f:
                log = json.load(f)
            
            if task_id:
                log = [entry for entry in log if entry['task_id'] == task_id]
            
            for entry in log:
                print(f"{entry['timestamp']}: {entry['task_id']} -> {entry['status']}")
        except FileNotFoundError:
            print("No time log found")
```

## Performance Considerations

### Database Performance

#### Query Optimization

```sql
-- Use indexes for common queries
CREATE INDEX idx_task_status_priority ON tasks(status, priority);
CREATE INDEX idx_task_created_at ON tasks(created_at);

-- Optimize dependency queries
CREATE INDEX idx_deps_compound ON dependencies(task_id, depends_on);

-- Use EXPLAIN QUERY PLAN to analyze performance
EXPLAIN QUERY PLAN 
SELECT * FROM tasks WHERE status = 'pending' ORDER BY priority DESC;
```

#### Connection Management

```python
def _get_connection(self):
    """Get database connection with optimization"""
    conn = sqlite3.connect(
        str(self.db_path),
        timeout=30.0,  # Longer timeout for busy systems
        isolation_level=None  # Autocommit mode for better concurrency
    )
    
    # Enable optimizations
    conn.execute("PRAGMA journal_mode=WAL")  # Better concurrency
    conn.execute("PRAGMA synchronous=NORMAL")  # Balance safety/performance
    conn.execute("PRAGMA cache_size=10000")  # Larger cache
    
    return conn
```

### Concurrency Optimization

#### Lock Management

```python
def _acquire_lock_with_backoff(self, timeout=5):
    """Acquire lock with exponential backoff"""
    self.db_dir.mkdir(parents=True, exist_ok=True)
    lock_fd = open(self.lock_file, 'w')
    
    backoff = 0.1
    start = time.time()
    
    while time.time() - start < timeout:
        try:
            fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            return lock_fd
        except IOError:
            time.sleep(backoff)
            backoff = min(backoff * 2, 1.0)  # Exponential backoff, max 1s
    
    raise TimeoutError("Could not acquire database lock")
```

#### Batch Operations

```python
def add_tasks_batch(self, tasks: List[Dict]) -> List[str]:
    """Add multiple tasks in a single transaction"""
    task_ids = []
    
    lock = None
    try:
        lock = self._acquire_lock()
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Start transaction
        cursor.execute("BEGIN TRANSACTION")
        
        for task_data in tasks:
            task_id = str(uuid.uuid4())[:8]
            cursor.execute("""
                INSERT INTO tasks (id, title, description, status, priority, 
                                  created_at, updated_at, created_by)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (task_id, task_data['title'], task_data.get('description', ''),
                  'pending', task_data.get('priority', 'medium'),
                  datetime.now().isoformat(), datetime.now().isoformat(),
                  self.agent_id))
            task_ids.append(task_id)
        
        # Commit all at once
        conn.commit()
        return task_ids
        
    except Exception as e:
        if conn:
            conn.rollback()
        raise e
    finally:
        if lock:
            self._release_lock(lock)
```

### Memory Optimization

#### Large Result Sets

```python
def list_tasks_paginated(self, page=1, page_size=50, **filters):
    """List tasks with pagination for large datasets"""
    offset = (page - 1) * page_size
    
    with sqlite3.connect(self.db_path) as conn:
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        query = "SELECT * FROM tasks WHERE 1=1"
        params = []
        
        # Add filters
        if filters.get('status'):
            query += " AND status = ?"
            params.append(filters['status'])
        
        # Add pagination
        query += " ORDER BY priority DESC, created_at DESC LIMIT ? OFFSET ?"
        params.extend([page_size, offset])
        
        cursor.execute(query, params)
        return [dict(row) for row in cursor.fetchall()]
```

#### Memory-Efficient Export

```python
def export_tasks_streaming(self, format="json", output_file=None):
    """Export tasks with streaming for large datasets"""
    import itertools
    
    def task_generator():
        """Generator to avoid loading all tasks into memory"""
        page = 1
        page_size = 100
        
        while True:
            tasks = self.list_tasks_paginated(page=page, page_size=page_size)
            if not tasks:
                break
            
            for task in tasks:
                yield task
            page += 1
    
    if format == "json":
        if output_file:
            with open(output_file, 'w') as f:
                f.write('[\n')
                for i, task in enumerate(task_generator()):
                    if i > 0:
                        f.write(',\n')
                    json.dump(task, f, indent=2, default=str)
                f.write('\n]')
        else:
            # Return generator for streaming
            return task_generator()
```

## Security Considerations

### Input Validation

#### SQL Injection Prevention

```python
def _validate_and_sanitize_input(self, input_value: str, max_length: int = None) -> str:
    """Validate and sanitize user input"""
    if not input_value:
        raise ValidationError("Input cannot be empty")
    
    # Remove null bytes
    sanitized = input_value.replace('\0', '')
    
    # Check length
    if max_length and len(sanitized) > max_length:
        raise ValidationError(f"Input too long (max {max_length} characters)")
    
    # Additional sanitization for specific contexts
    if any(char in sanitized for char in ['<', '>', '&']):
        # HTML escape if needed
        import html
        sanitized = html.escape(sanitized)
    
    return sanitized

# Always use parameterized queries
def safe_query_example(self, task_id: str):
    """Example of safe database query"""
    with sqlite3.connect(self.db_path) as conn:
        cursor = conn.cursor()
        
        # SAFE: Parameterized query
        cursor.execute("SELECT * FROM tasks WHERE id = ?", (task_id,))
        
        # UNSAFE: String formatting (never do this)
        # cursor.execute(f"SELECT * FROM tasks WHERE id = '{task_id}'")
```

#### File Path Validation

```python
def _validate_file_path(self, file_path: str) -> str:
    """Validate file path to prevent directory traversal"""
    import os.path
    
    # Normalize path
    normalized = os.path.normpath(file_path)
    
    # Check for directory traversal attempts
    if '..' in normalized or normalized.startswith('/'):
        raise ValidationError("Invalid file path: directory traversal detected")
    
    # Check for absolute paths on Windows
    if os.path.isabs(normalized):
        raise ValidationError("Absolute paths not allowed")
    
    return normalized
```

### Access Control

#### Agent Authentication

```python
def _verify_agent_authorization(self, task_id: str, required_action: str) -> bool:
    """Verify agent has permission for action"""
    with sqlite3.connect(self.db_path) as conn:
        cursor = conn.cursor()
        
        # Check task ownership or assignment
        cursor.execute("""
            SELECT created_by, assignee FROM tasks WHERE id = ?
        """, (task_id,))
        
        result = cursor.fetchone()
        if not result:
            return False
        
        created_by, assignee = result
        
        # Check permissions based on action
        if required_action == 'delete':
            # Only creator can delete
            return created_by == self.agent_id
        elif required_action == 'update':
            # Creator or assignee can update
            return created_by == self.agent_id or assignee == self.agent_id
        elif required_action == 'view':
            # Anyone can view (adjust based on requirements)
            return True
        
        return False
```

#### Data Encryption (Optional)

```python
def _encrypt_sensitive_data(self, data: str) -> str:
    """Encrypt sensitive data before storing"""
    from cryptography.fernet import Fernet
    import base64
    
    # Use environment variable for key
    key = os.environ.get('TM_ENCRYPTION_KEY')
    if not key:
        return data  # No encryption if no key
    
    f = Fernet(key.encode())
    encrypted = f.encrypt(data.encode())
    return base64.b64encode(encrypted).decode()

def _decrypt_sensitive_data(self, encrypted_data: str) -> str:
    """Decrypt sensitive data after retrieval"""
    from cryptography.fernet import Fernet
    import base64
    
    key = os.environ.get('TM_ENCRYPTION_KEY')
    if not key:
        return encrypted_data  # No decryption if no key
    
    f = Fernet(key.encode())
    encrypted_bytes = base64.b64decode(encrypted_data.encode())
    return f.decrypt(encrypted_bytes).decode()
```

### Audit and Logging

#### Comprehensive Audit Trail

```python
def _create_audit_log(self, task_id: str, action: str, old_value: Any = None, 
                     new_value: Any = None, additional_info: Dict = None):
    """Create comprehensive audit log entry"""
    with sqlite3.connect(self.db_path) as conn:
        cursor = conn.cursor()
        
        audit_data = {
            'task_id': task_id,
            'action': action,
            'old_value': json.dumps(old_value, default=str) if old_value else None,
            'new_value': json.dumps(new_value, default=str) if new_value else None,
            'changed_by': self.agent_id,
            'timestamp': datetime.now().isoformat(),
            'ip_address': os.environ.get('REMOTE_ADDR'),  # If available
            'user_agent': os.environ.get('HTTP_USER_AGENT'),  # If available
            'additional_info': json.dumps(additional_info) if additional_info else None
        }
        
        cursor.execute("""
            INSERT INTO audit_log (task_id, action, old_value, new_value, 
                                  changed_by, changed_at, additional_info)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (audit_data['task_id'], audit_data['action'], 
              audit_data['old_value'], audit_data['new_value'],
              audit_data['changed_by'], audit_data['timestamp'],
              audit_data['additional_info']))
```

## Contributing Guidelines

### Contribution Process

#### 1. Issue First

```markdown
# Before starting work:
1. Check existing issues and discussions
2. Create an issue describing the change
3. Wait for feedback from maintainers
4. Get approval before implementing large changes
```

#### 2. Fork and Branch

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/task-orchestrator.git
cd task-orchestrator

# Create feature branch
git checkout -b feature/your-feature-name
```

#### 3. Development Standards

```bash
# Before committing:
1. Run all tests: ./test_tm.sh && ./test_edge_cases.sh
2. Check code style: black --check *.py
3. Run type checking: mypy *.py
4. Update documentation if needed
5. Add tests for new functionality
```

#### 4. Pull Request Process

```markdown
# Pull Request Template

## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update

## Testing
- [ ] All existing tests pass
- [ ] New tests added for new functionality
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or clearly documented)
```

### Code Review Guidelines

#### For Contributors

```markdown
# Preparing for Review:
1. **Self-Review**: Review your own code first
2. **Documentation**: Update relevant docs
3. **Tests**: Include comprehensive tests
4. **Commit Messages**: Use clear, descriptive messages
5. **Small PRs**: Keep changes focused and small
```

#### For Reviewers

```markdown
# Review Checklist:
1. **Functionality**: Does it work as intended?
2. **Tests**: Are there adequate tests?
3. **Performance**: Any performance implications?
4. **Security**: Any security concerns?
5. **Style**: Follows project conventions?
6. **Documentation**: Is documentation updated?
```

### Release Process

#### Version Management

```bash
# Semantic versioning: MAJOR.MINOR.PATCH
# 1.0.0 -> 1.0.1 (patch: bug fixes)
# 1.0.1 -> 1.1.0 (minor: new features, backward compatible)
# 1.1.0 -> 2.0.0 (major: breaking changes)
```

#### Release Checklist

```markdown
# Pre-Release:
- [ ] All tests pass on CI
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped in relevant files
- [ ] Release notes prepared

# Release:
- [ ] Tag created: git tag v1.0.0
- [ ] Release published on GitHub
- [ ] Documentation deployed
- [ ] Community notified

# Post-Release:
- [ ] Monitor for issues
- [ ] Address critical bugs quickly
- [ ] Plan next release cycle
```

This comprehensive developer guide provides everything needed to understand, contribute to, and extend the Task Orchestrator codebase. For specific questions or clarifications, please refer to the project's GitHub discussions or create an issue.