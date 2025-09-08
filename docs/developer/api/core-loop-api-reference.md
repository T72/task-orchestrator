# Core Loop API Reference

## Overview

This document provides comprehensive API documentation for the Core Loop features introduced in Task Orchestrator v2.3. The Core Loop extends the basic task management functionality with success criteria, feedback mechanisms, progress tracking, and metrics.

## Table of Contents

- [TaskManager Core Loop Methods](#taskmanager-core-loop-methods)
- [Configuration Manager](#configuration-manager)
- [Migration System](#migration-system)
- [Criteria Validator](#criteria-validator)
- [Metrics Calculator](#metrics-calculator)
- [Telemetry Capture](#telemetry-capture)
- [Error Handler](#error-handler)
- [Examples](#examples)

## TaskManager Core Loop Methods

### `add()` - Enhanced Task Creation

Creates a new task with optional Core Loop features.

**Signature:**
```python
def add(self, title, description=None, priority='medium', assignee=None, 
        depends_on=None, file_refs=None, criteria=None, deadline=None, 
        estimated_hours=None) -> str
```

**Parameters:**
- `title` (str): Task description (required)
- `description` (str): Detailed task description
- `priority` (str): Priority level ('low', 'medium', 'high', 'critical')
- `assignee` (str): Agent or user assigned to the task
- `depends_on` (list): List of task IDs this task depends on
- `file_refs` (list): List of file references
- `criteria` (str): JSON string array of success criteria objects
- `deadline` (str): ISO 8601 formatted deadline
- `estimated_hours` (float): Estimated time to complete

**Returns:**
- `str`: Unique task ID (8-character hex string)

**Raises:**
- `ValueError`: Invalid criteria JSON format
- `ValueError`: Invalid deadline format
- `ValueError`: Invalid priority value

**Example:**
```python
from task_orchestrator import TaskManager

tm = TaskManager()

# Basic task
task_id = tm.add("Implement user authentication")

# Task with Core Loop features
task_id = tm.add(
    title="Build payment integration",
    criteria='[{"criterion":"All tests pass","measurable":"true"},
              {"criterion":"PCI compliant","measurable":"compliance_check == passed"}]',
    deadline="2025-12-31T17:00:00Z",
    estimated_hours=40,
    priority="critical"
)
```

### `complete()` - Enhanced Task Completion

Marks a task as completed with optional validation and summary.

**Signature:**
```python
def complete(self, task_id, validate=False, actual_hours=None, 
             summary=None, impact_review=False) -> bool
```

**Parameters:**
- `task_id` (str): Task identifier
- `validate` (bool): Run success criteria validation
- `actual_hours` (float): Actual time spent on task
- `summary` (str): Completion summary and learnings
- `impact_review` (bool): Trigger impact analysis

**Returns:**
- `bool`: True if completed successfully

**Raises:**
- `TaskNotFoundError`: Task ID does not exist
- `ValidationError`: Criteria validation failed
- `StateError`: Task already completed

**Example:**
```python
# Simple completion
tm.complete("abc12345")

# Completion with validation and summary
success = tm.complete(
    task_id="abc12345",
    validate=True,
    actual_hours=35.5,
    summary="Implemented Stripe integration with full PCI compliance. "
            "All tests passing. Added comprehensive error handling."
)

if success:
    print("Task completed and validated")
```

### `progress()` - Progress Tracking

Adds a progress update to a task.

**Signature:**
```python
def progress(self, task_id, message) -> bool
```

**Parameters:**
- `task_id` (str): Task identifier
- `message` (str): Progress update message

**Returns:**
- `bool`: True if progress was recorded

**Raises:**
- `TaskNotFoundError`: Task ID does not exist

**Example:**
```python
# Simple progress update
tm.progress("abc12345", "Started investigation")

# Percentage-based progress
tm.progress("abc12345", "25% - Database schema designed")
tm.progress("abc12345", "50% - Backend API implemented")
tm.progress("abc12345", "75% - Frontend integration complete")

# Detailed findings
tm.progress("abc12345", "Found root cause: race condition in auth flow")
```

### `feedback()` - Quality Feedback

Adds feedback scores to a completed task.

**Signature:**
```python
def feedback(self, task_id, quality=None, timeliness=None, note=None) -> bool
```

**Parameters:**
- `task_id` (str): Task identifier
- `quality` (int): Quality score 1-5 (5 = exceptional)
- `timeliness` (int): Timeliness score 1-5 (5 = well ahead of schedule)
- `note` (str): Additional feedback notes

**Returns:**
- `bool`: True if feedback was recorded

**Raises:**
- `TaskNotFoundError`: Task ID does not exist
- `ValueError`: Invalid score values (must be 1-5)
- `StateError`: Task not completed

**Score Guidelines:**
- **Quality Scale:**
  - 5: Exceptional quality, exceeds all expectations
  - 4: Above expectations, high quality
  - 3: Meets expectations, good quality
  - 2: Below expectations, needs improvement
  - 1: Poor quality, significant issues

- **Timeliness Scale:**
  - 5: Well ahead of schedule
  - 4: Ahead of schedule
  - 3: On time
  - 2: Late
  - 1: Significantly late

**Example:**
```python
# Add feedback to completed task
tm.feedback(
    task_id="abc12345",
    quality=5,
    timeliness=4,
    note="Excellent implementation with comprehensive tests. "
         "Slightly delayed due to additional security requirements."
)
```

### `metrics()` - Performance Metrics

Retrieves aggregated metrics and analytics.

**Signature:**
```python
def metrics(self, feedback=False, telemetry=False, time_tracking=False) -> dict
```

**Parameters:**
- `feedback` (bool): Include feedback metrics
- `telemetry` (bool): Include telemetry data
- `time_tracking` (bool): Include time tracking metrics

**Returns:**
- `dict`: Metrics data with requested categories

**Example:**
```python
# Get feedback metrics
metrics = tm.metrics(feedback=True)
print(f"Average quality: {metrics['feedback']['avg_quality']}/5")
print(f"Success rate: {metrics['feedback']['success_rate']}%")

# Get all metrics
all_metrics = tm.metrics(feedback=True, telemetry=True, time_tracking=True)
```

## Configuration Manager

### ConfigManager Class

Manages Core Loop feature configuration.

```python
from config_manager import ConfigManager

config = ConfigManager()
```

### `enable_feature(feature_name)`

Enables a specific Core Loop feature.

**Parameters:**
- `feature_name` (str): Feature to enable

**Valid Features:**
- `success-criteria`
- `feedback`
- `telemetry`
- `completion-summaries`
- `time-tracking`
- `deadlines`

**Example:**
```python
config.enable_feature('feedback')
config.enable_feature('success-criteria')
```

### `disable_feature(feature_name)`

Disables a specific Core Loop feature.

**Example:**
```python
config.disable_feature('telemetry')
```

### `set_minimal_mode(enabled=True)`

Enables or disables minimal mode (all Core Loop features off).

**Example:**
```python
# Enable minimal mode
config.set_minimal_mode(True)

# Disable minimal mode (restore previous settings)
config.set_minimal_mode(False)
```

### `get_config()`

Returns current configuration as dictionary.

**Returns:**
- `dict`: Current feature configuration

**Example:**
```python
current_config = config.get_config()
print(f"Feedback enabled: {current_config['feedback']}")
```

## Migration System

### MigrationManager Class

Handles database schema migrations for Core Loop features.

```python
from migrations import MigrationManager

migrator = MigrationManager()
```

### `apply_migrations()`

Applies all pending migrations.

**Returns:**
- `bool`: True if all migrations applied successfully

**Raises:**
- `MigrationError`: Migration failed

**Example:**
```python
# Apply migrations with automatic backup
success = migrator.apply_migrations()
if success:
    print("All migrations applied successfully")
```

### `get_status()`

Returns migration status information.

**Returns:**
- `dict`: Migration status with applied and pending migrations

**Example:**
```python
status = migrator.get_status()
print(f"Applied: {status['applied']}")
print(f"Pending: {status['pending']}")
print(f"Up to date: {status['up_to_date']}")
```

### `rollback()`

Rolls back the last migration using backup.

**Returns:**
- `bool`: True if rollback successful

**Example:**
```python
success = migrator.rollback()
if success:
    print("Migration rolled back successfully")
```

## Criteria Validator

### CriteriaValidator Class

Validates success criteria and evaluates expressions.

```python
from criteria_validator import CriteriaValidator

validator = CriteriaValidator()
```

### `validate(criteria_list, context=None)`

Validates a list of success criteria.

**Parameters:**
- `criteria_list` (list): List of criteria objects
- `context` (dict): Context variables for expression evaluation

**Returns:**
- `dict`: Validation results with pass/fail status

**Criteria Object Format:**
```json
{
  "criterion": "Human-readable description",
  "measurable": "boolean_expression_or_true/false"
}
```

**Example:**
```python
criteria = [
    {"criterion": "All tests pass", "measurable": "true"},
    {"criterion": "Code coverage > 80%", "measurable": "coverage > 80"},
    {"criterion": "Performance acceptable", "measurable": "response_time < 200"}
]

context = {
    "coverage": 85,
    "response_time": 150
}

result = validator.validate(criteria, context)
print(f"Overall pass: {result['overall_pass']}")
print(f"Results: {result['results']}")
```

## Metrics Calculator

### MetricsCalculator Class

Calculates aggregated metrics from task data.

```python
from metrics_calculator import MetricsCalculator

calc = MetricsCalculator()
```

### `calculate_feedback_metrics()`

Calculates feedback-related metrics.

**Returns:**
- `dict`: Feedback metrics including averages and distributions

**Example:**
```python
feedback_metrics = calc.calculate_feedback_metrics()
print(f"Average quality: {feedback_metrics['avg_quality']}")
print(f"Average timeliness: {feedback_metrics['avg_timeliness']}")
print(f"Total tasks with feedback: {feedback_metrics['tasks_with_feedback']}")
```

### `calculate_time_metrics()`

Calculates time tracking metrics.

**Returns:**
- `dict`: Time-related metrics including estimation accuracy

**Example:**
```python
time_metrics = calc.calculate_time_metrics()
print(f"Average estimation accuracy: {time_metrics['estimation_accuracy']}%")
print(f"Total estimated hours: {time_metrics['total_estimated']}")
print(f"Total actual hours: {time_metrics['total_actual']}")
```

## Error Handler

### ErrorHandler Class

Provides robust error handling and recovery strategies.

```python
from error_handler import ErrorHandler

handler = ErrorHandler()
```

### `handle_error(error, context=None)`

Handles errors with appropriate recovery strategies.

**Parameters:**
- `error` (Exception): The error to handle
- `context` (dict): Additional context for error handling

**Returns:**
- `dict`: Error handling result with recovery actions

## Examples

### Complete Core Loop Workflow

```python
from task_orchestrator import TaskManager

# Initialize
tm = TaskManager()

# 1. Create task with success criteria and time estimate
task_id = tm.add(
    title="Implement OAuth integration",
    criteria='[{"criterion":"All OAuth providers work","measurable":"true"},
              {"criterion":"Security review passed","measurable":"security_score >= 9"}]',
    deadline="2025-12-31T17:00:00Z",
    estimated_hours=20
)

# 2. Track progress throughout development
tm.progress(task_id, "10% - Researching OAuth 2.0 specification")
tm.progress(task_id, "30% - Google OAuth integration complete")
tm.progress(task_id, "60% - GitHub OAuth integration complete")
tm.progress(task_id, "85% - Security review in progress")

# 3. Complete with validation and summary
context = {"security_score": 9.5}
tm.complete(
    task_id=task_id,
    validate=True,
    actual_hours=18.5,
    summary="Successfully implemented OAuth for Google and GitHub. "
            "Security review passed with score 9.5/10. "
            "Added comprehensive error handling and user feedback."
)

# 4. Add quality feedback
tm.feedback(
    task_id=task_id,
    quality=5,
    timeliness=5,
    note="Exceptional work. Delivered ahead of schedule with excellent security."
)

# 5. View metrics
metrics = tm.metrics(feedback=True, time_tracking=True)
print(f"Team quality average: {metrics['feedback']['avg_quality']}")
print(f"Estimation accuracy: {metrics['time']['estimation_accuracy']}%")
```

### Custom Validation Context

```python
# Task with complex criteria requiring context
task_id = tm.add(
    title="Optimize database performance",
    criteria='[{"criterion":"Query time improved","measurable":"new_time < old_time * 0.5"},
              {"criterion":"Memory usage acceptable","measurable":"memory_mb < 1000"}]'
)

# Complete with context for validation
context = {
    "old_time": 2000,  # milliseconds
    "new_time": 800,   # milliseconds
    "memory_mb": 750
}

tm.complete(task_id, validate=True, context=context)
```

### Configuration Management

```python
from config_manager import ConfigManager

config = ConfigManager()

# Start with minimal configuration
config.set_minimal_mode(True)

# Gradually enable features as team adopts them
config.enable_feature('feedback')
config.enable_feature('success-criteria')

# Check current state
current = config.get_config()
enabled_features = [k for k, v in current.items() if v]
print(f"Enabled features: {enabled_features}")
```

## Error Handling

### Common Exceptions

- `TaskNotFoundError`: Task ID does not exist
- `ValidationError`: Criteria validation failed
- `StateError`: Invalid state transition
- `ConfigurationError`: Invalid configuration
- `MigrationError`: Database migration failed

### Exception Handling Example

```python
try:
    tm.complete("invalid_id", validate=True)
except TaskNotFoundError:
    print("Task not found")
except ValidationError as e:
    print(f"Validation failed: {e}")
except Exception as e:
    print(f"Unexpected error: {e}")
```

## Thread Safety

Core Loop operations are thread-safe through database-level locking:

```python
import threading

def worker(task_id):
    tm = TaskManager()
    tm.progress(task_id, f"Update from {threading.current_thread().name}")

# Multiple threads can safely update the same task
threads = []
for i in range(5):
    t = threading.Thread(target=worker, args=("abc12345",))
    threads.append(t)
    t.start()

for t in threads:
    t.join()
```

---

## See Also

- [Database Schema Documentation](../database/core-loop-schema.md)
- [Architecture Overview](../architecture/core-loop-architecture.md)
- [Extension Guide](../extending/extending-core-loop.md)
- [Integration Patterns](../integrations/integration-patterns.md)