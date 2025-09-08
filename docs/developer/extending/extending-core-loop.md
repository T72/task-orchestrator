# Extending Core Loop Features

## Overview

Task Orchestrator's Core Loop is designed for extensibility. This guide shows how to create custom validators, metrics calculators, plugins, and integrations to extend the system's capabilities.

## Table of Contents

- [Custom Validators](#custom-validators)
- [Custom Metrics](#custom-metrics)
- [Hook System](#hook-system)
- [Plugin Architecture](#plugin-architecture)
- [Event System](#event-system)
- [Integration Examples](#integration-examples)
- [Development Setup](#development-setup)
- [Testing Extensions](#testing-extensions)

## Custom Validators

### Validator Interface

All custom validators must implement the `ValidatorInterface`:

```python
from abc import ABC, abstractmethod
from typing import Dict, Any, List

class ValidatorInterface(ABC):
    @abstractmethod
    def validate(self, criterion: Dict[str, Any], context: Dict[str, Any] = None) -> bool:
        """
        Validate a single criterion.
        
        Args:
            criterion: The criterion object to validate
            context: Optional context variables for validation
            
        Returns:
            bool: True if criterion passes, False otherwise
        """
        pass
    
    @abstractmethod
    def get_name(self) -> str:
        """Return the unique name for this validator."""
        pass
    
    def get_description(self) -> str:
        """Return human-readable description of this validator."""
        return f"Validator: {self.get_name()}"
```

### Example 1: HTTP Status Validator

```python
import requests
from typing import Dict, Any

class HttpStatusValidator:
    """Validates HTTP endpoints return expected status codes."""
    
    def validate(self, criterion: Dict[str, Any], context: Dict[str, Any] = None) -> bool:
        """
        Validates HTTP endpoint status.
        
        Expected criterion format:
        {
            "criterion": "API endpoint is healthy",
            "measurable": "http_status:https://api.example.com/health:200"
        }
        """
        measurable = criterion.get('measurable', '')
        
        if not measurable.startswith('http_status:'):
            return False
            
        try:
            parts = measurable.split(':')
            if len(parts) != 3:
                return False
                
            _, url, expected_status = parts
            expected_status = int(expected_status)
            
            response = requests.get(url, timeout=5)
            return response.status_code == expected_status
            
        except (requests.RequestException, ValueError):
            return False
    
    def get_name(self) -> str:
        return "http_status"
    
    def get_description(self) -> str:
        return "Validates HTTP endpoint status codes"
```

### Example 2: File System Validator

```python
import os
import re
from pathlib import Path

class FileSystemValidator:
    """Validates file system conditions."""
    
    def validate(self, criterion: Dict[str, Any], context: Dict[str, Any] = None) -> bool:
        """
        Validates file system conditions.
        
        Supported formats:
        - "file_exists:/path/to/file"
        - "file_contains:/path/to/file:pattern"
        - "file_size:/path/to/file:>1024"
        """
        measurable = criterion.get('measurable', '')
        
        if measurable.startswith('file_exists:'):
            file_path = measurable[12:]  # Remove 'file_exists:'
            return Path(file_path).exists()
            
        elif measurable.startswith('file_contains:'):
            parts = measurable[14:].split(':', 1)  # Remove 'file_contains:'
            if len(parts) != 2:
                return False
            file_path, pattern = parts
            
            try:
                with open(file_path, 'r') as f:
                    content = f.read()
                return re.search(pattern, content) is not None
            except (IOError, OSError):
                return False
                
        elif measurable.startswith('file_size:'):
            parts = measurable[10:].split(':', 1)  # Remove 'file_size:'
            if len(parts) != 2:
                return False
            file_path, size_condition = parts
            
            try:
                actual_size = Path(file_path).stat().st_size
                
                # Parse condition like ">1024", "<=500", "==1000"
                if size_condition.startswith('>='):
                    return actual_size >= int(size_condition[2:])
                elif size_condition.startswith('<='):
                    return actual_size <= int(size_condition[2:])
                elif size_condition.startswith('>'):
                    return actual_size > int(size_condition[1:])
                elif size_condition.startswith('<'):
                    return actual_size < int(size_condition[1:])
                elif size_condition.startswith('=='):
                    return actual_size == int(size_condition[2:])
                else:
                    return actual_size == int(size_condition)
                    
            except (OSError, ValueError):
                return False
        
        return False
    
    def get_name(self) -> str:
        return "filesystem"
```

### Example 3: Performance Validator

```python
import time
import psutil
from typing import Dict, Any

class PerformanceValidator:
    """Validates system performance metrics."""
    
    def validate(self, criterion: Dict[str, Any], context: Dict[str, Any] = None) -> bool:
        """
        Validates performance metrics.
        
        Supported formats:
        - "cpu_usage:<90"
        - "memory_usage:<80"
        - "response_time:<200"
        """
        measurable = criterion.get('measurable', '')
        
        try:
            if measurable.startswith('cpu_usage:'):
                condition = measurable[10:]
                current_cpu = psutil.cpu_percent(interval=1)
                return self._evaluate_condition(current_cpu, condition)
                
            elif measurable.startswith('memory_usage:'):
                condition = measurable[13:]
                current_memory = psutil.virtual_memory().percent
                return self._evaluate_condition(current_memory, condition)
                
            elif measurable.startswith('response_time:'):
                condition = measurable[14:]
                # Get response time from context
                response_time = context.get('response_time', 0) if context else 0
                return self._evaluate_condition(response_time, condition)
                
        except Exception:
            return False
            
        return False
    
    def _evaluate_condition(self, actual: float, condition: str) -> bool:
        """Evaluate a numeric condition like '<90', '>=80', etc."""
        if condition.startswith('>='):
            return actual >= float(condition[2:])
        elif condition.startswith('<='):
            return actual <= float(condition[2:])
        elif condition.startswith('>'):
            return actual > float(condition[1:])
        elif condition.startswith('<'):
            return actual < float(condition[1:])
        elif condition.startswith('=='):
            return actual == float(condition[2:])
        else:
            return actual == float(condition)
    
    def get_name(self) -> str:
        return "performance"
```

### Registering Custom Validators

```python
# In your extension file
from criteria_validator import CriteriaValidator

# Create validator registry
validator_registry = CriteriaValidator()

# Register custom validators
validator_registry.register_validator(HttpStatusValidator())
validator_registry.register_validator(FileSystemValidator())
validator_registry.register_validator(PerformanceValidator())

# Use in TaskManager
tm = TaskManager()
tm.set_validator_registry(validator_registry)

# Now you can use custom validators in criteria
task_id = tm.add(
    "Deploy API",
    criteria='[
        {"criterion":"API is responding","measurable":"http_status:https://api.example.com:200"},
        {"criterion":"Config file exists","measurable":"file_exists:/etc/myapp/config.json"},
        {"criterion":"Low CPU usage","measurable":"cpu_usage:<80"}
    ]'
)
```

## Custom Metrics

### Metrics Interface

```python
from abc import ABC, abstractmethod
from typing import Dict, List, Any

class MetricsCalculatorInterface(ABC):
    @abstractmethod
    def calculate(self, tasks: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Calculate custom metrics from task data.
        
        Args:
            tasks: List of task dictionaries
            
        Returns:
            Dict containing calculated metrics
        """
        pass
    
    @abstractmethod
    def get_name(self) -> str:
        """Return unique name for this metrics calculator."""
        pass
```

### Example 1: Velocity Calculator

```python
from datetime import datetime, timedelta
from collections import defaultdict

class VelocityCalculator:
    """Calculates team velocity metrics."""
    
    def calculate(self, tasks: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Calculate velocity metrics."""
        now = datetime.now()
        
        # Group tasks by week
        weekly_completions = defaultdict(int)
        weekly_hours = defaultdict(float)
        
        for task in tasks:
            if task['status'] == 'completed' and task['completed_at']:
                completed_date = datetime.fromisoformat(task['completed_at'].replace('Z', '+00:00'))
                week_start = completed_date - timedelta(days=completed_date.weekday())
                week_key = week_start.strftime('%Y-W%U')
                
                weekly_completions[week_key] += 1
                if task.get('actual_hours'):
                    weekly_hours[week_key] += task['actual_hours']
        
        # Calculate averages
        if weekly_completions:
            avg_tasks_per_week = sum(weekly_completions.values()) / len(weekly_completions)
            avg_hours_per_week = sum(weekly_hours.values()) / len(weekly_hours)
        else:
            avg_tasks_per_week = 0
            avg_hours_per_week = 0
        
        return {
            'avg_tasks_per_week': round(avg_tasks_per_week, 2),
            'avg_hours_per_week': round(avg_hours_per_week, 2),
            'weekly_breakdown': dict(weekly_completions),
            'trend': self._calculate_trend(weekly_completions)
        }
    
    def _calculate_trend(self, weekly_data: Dict[str, int]) -> str:
        """Calculate if velocity is increasing, decreasing, or stable."""
        if len(weekly_data) < 2:
            return 'insufficient_data'
        
        weeks = sorted(weekly_data.keys())
        recent_weeks = weeks[-4:]  # Last 4 weeks
        
        if len(recent_weeks) < 2:
            return 'insufficient_data'
        
        first_half = sum(weekly_data[week] for week in recent_weeks[:len(recent_weeks)//2])
        second_half = sum(weekly_data[week] for week in recent_weeks[len(recent_weeks)//2:])
        
        if second_half > first_half * 1.1:
            return 'increasing'
        elif second_half < first_half * 0.9:
            return 'decreasing'
        else:
            return 'stable'
    
    def get_name(self) -> str:
        return "velocity"
```

### Example 2: Quality Metrics Calculator

```python
class QualityMetricsCalculator:
    """Calculates quality-related metrics."""
    
    def calculate(self, tasks: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Calculate quality metrics."""
        tasks_with_feedback = [t for t in tasks if t.get('feedback_quality')]
        
        if not tasks_with_feedback:
            return {
                'error': 'No tasks with quality feedback found',
                'recommendations': ['Add feedback to completed tasks to enable quality metrics']
            }
        
        # Quality distribution
        quality_scores = [t['feedback_quality'] for t in tasks_with_feedback]
        quality_distribution = {i: quality_scores.count(i) for i in range(1, 6)}
        
        # Quality by assignee
        assignee_quality = defaultdict(list)
        for task in tasks_with_feedback:
            if task.get('assignee'):
                assignee_quality[task['assignee']].append(task['feedback_quality'])
        
        assignee_averages = {
            assignee: round(sum(scores) / len(scores), 2)
            for assignee, scores in assignee_quality.items()
        }
        
        # Quality trends over time
        monthly_quality = defaultdict(list)
        for task in tasks_with_feedback:
            if task.get('completed_at'):
                month = task['completed_at'][:7]  # YYYY-MM
                monthly_quality[month].append(task['feedback_quality'])
        
        monthly_averages = {
            month: round(sum(scores) / len(scores), 2)
            for month, scores in monthly_quality.items()
        }
        
        return {
            'overall_average': round(sum(quality_scores) / len(quality_scores), 2),
            'quality_distribution': quality_distribution,
            'assignee_averages': assignee_averages,
            'monthly_trends': monthly_averages,
            'total_rated_tasks': len(tasks_with_feedback),
            'excellence_rate': len([s for s in quality_scores if s >= 4]) / len(quality_scores) * 100
        }
    
    def get_name(self) -> str:
        return "quality"
```

### Registering Custom Metrics

```python
# Register custom metrics calculators
from metrics_calculator import MetricsCalculator

metrics_calc = MetricsCalculator()
metrics_calc.register_calculator(VelocityCalculator())
metrics_calc.register_calculator(QualityMetricsCalculator())

# Use in TaskManager
tm = TaskManager()
tm.set_metrics_calculator(metrics_calc)

# Get custom metrics
velocity_metrics = tm.metrics(custom=['velocity'])
quality_metrics = tm.metrics(custom=['quality'])
all_custom = tm.metrics(custom=['velocity', quality'])
```

## Hook System

### Available Hooks

Task Orchestrator provides several hooks for extending functionality:

```python
from typing import Dict, Any, List

class TaskHooks:
    """Hook definitions for task lifecycle events."""
    
    def pre_create(self, task_data: Dict[str, Any]) -> Dict[str, Any]:
        """Called before task creation. Can modify task data."""
        return task_data
    
    def post_create(self, task: Dict[str, Any]) -> None:
        """Called after task creation."""
        pass
    
    def pre_complete(self, task_id: str, completion_data: Dict[str, Any]) -> Dict[str, Any]:
        """Called before task completion. Can modify completion data."""
        return completion_data
    
    def post_complete(self, task: Dict[str, Any]) -> None:
        """Called after task completion."""
        pass
    
    def pre_progress(self, task_id: str, message: str) -> str:
        """Called before progress update. Can modify message."""
        return message
    
    def post_progress(self, task_id: str, message: str) -> None:
        """Called after progress update."""
        pass
```

### Example Hook Implementation

```python
import requests
import json
from datetime import datetime

class SlackNotificationHook:
    """Sends Slack notifications for task events."""
    
    def __init__(self, webhook_url: str, channel: str = None):
        self.webhook_url = webhook_url
        self.channel = channel
    
    def post_create(self, task: Dict[str, Any]) -> None:
        """Notify when high-priority tasks are created."""
        if task.get('priority') in ['high', 'critical']:
            self._send_notification(
                f"🚨 High-priority task created: {task['title']}",
                f"Priority: {task['priority']}\nAssignee: {task.get('assignee', 'Unassigned')}"
            )
    
    def post_complete(self, task: Dict[str, Any]) -> None:
        """Notify when tasks are completed."""
        emoji = "🎉" if task.get('feedback_quality', 0) >= 4 else "✅"
        
        message = f"{emoji} Task completed: {task['title']}"
        details = f"Completed by: {task.get('assignee', 'Unknown')}"
        
        if task.get('actual_hours'):
            details += f"\nTime spent: {task['actual_hours']} hours"
        
        if task.get('feedback_quality'):
            details += f"\nQuality score: {task['feedback_quality']}/5"
        
        self._send_notification(message, details)
    
    def _send_notification(self, title: str, details: str) -> None:
        """Send notification to Slack."""
        payload = {
            "text": title,
            "blocks": [
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": f"*{title}*\n{details}"
                    }
                }
            ]
        }
        
        if self.channel:
            payload["channel"] = self.channel
        
        try:
            requests.post(self.webhook_url, json=payload, timeout=5)
        except requests.RequestException:
            # Ignore notification failures
            pass

class AutoProgressHook:
    """Automatically updates progress based on git commits."""
    
    def __init__(self, git_repo_path: str):
        self.git_repo_path = git_repo_path
    
    def post_create(self, task: Dict[str, Any]) -> None:
        """Set up git hook for this task."""
        task_id = task['id']
        self._setup_git_hook(task_id)
    
    def _setup_git_hook(self, task_id: str) -> None:
        """Create post-commit git hook."""
        hook_script = f"""#!/bin/bash
# Auto-progress hook for task {task_id}

commit_message=$(git log -1 --pretty=%B)
if echo "$commit_message" | grep -q "#{task_id}"; then
    echo "Updating progress for task {task_id}"
    ./tm progress {task_id} "Git commit: $(echo "$commit_message" | head -1)"
fi
"""
        
        hook_path = f"{self.git_repo_path}/.git/hooks/post-commit"
        try:
            with open(hook_path, 'a') as f:
                f.write(hook_script)
            os.chmod(hook_path, 0o755)
        except IOError:
            # Ignore if we can't set up git hook
            pass
```

### Registering Hooks

```python
# Register hooks with TaskManager
tm = TaskManager()

# Add Slack notifications
slack_hook = SlackNotificationHook(
    webhook_url="https://hooks.slack.com/services/T00/B00/XXXX",
    channel="#development"
)
tm.add_hook(slack_hook)

# Add auto-progress tracking
auto_progress = AutoProgressHook("/path/to/git/repo")
tm.add_hook(auto_progress)

# Hooks will now be called automatically during task operations
```

## Plugin Architecture

### Plugin Interface

```python
from abc import ABC, abstractmethod

class TaskOrchestratorPlugin(ABC):
    """Base class for Task Orchestrator plugins."""
    
    @abstractmethod
    def get_name(self) -> str:
        """Return plugin name."""
        pass
    
    @abstractmethod
    def get_version(self) -> str:
        """Return plugin version."""
        pass
    
    def initialize(self, config: Dict[str, Any]) -> None:
        """Initialize plugin with configuration."""
        pass
    
    def shutdown(self) -> None:
        """Clean up plugin resources."""
        pass
    
    def get_hooks(self) -> List[Any]:
        """Return list of hook instances provided by this plugin."""
        return []
    
    def get_validators(self) -> List[Any]:
        """Return list of validator instances provided by this plugin."""
        return []
    
    def get_metrics_calculators(self) -> List[Any]:
        """Return list of metrics calculator instances."""
        return []
```

### Example Plugin: JIRA Integration

```python
import requests
from base64 import b64encode

class JiraIntegrationPlugin(TaskOrchestratorPlugin):
    """Plugin for JIRA integration."""
    
    def __init__(self):
        self.jira_url = None
        self.auth_token = None
        self.project_key = None
    
    def get_name(self) -> str:
        return "jira_integration"
    
    def get_version(self) -> str:
        return "1.0.0"
    
    def initialize(self, config: Dict[str, Any]) -> None:
        """Initialize JIRA connection."""
        self.jira_url = config.get('jira_url')
        self.auth_token = config.get('auth_token')
        self.project_key = config.get('project_key')
        
        if not all([self.jira_url, self.auth_token, self.project_key]):
            raise ValueError("JIRA configuration incomplete")
    
    def get_hooks(self) -> List[Any]:
        """Return JIRA sync hooks."""
        return [JiraSyncHook(self.jira_url, self.auth_token, self.project_key)]
    
    def get_validators(self) -> List[Any]:
        """Return JIRA-related validators."""
        return [JiraStatusValidator(self.jira_url, self.auth_token)]

class JiraSyncHook:
    """Synchronizes tasks with JIRA issues."""
    
    def __init__(self, jira_url: str, auth_token: str, project_key: str):
        self.jira_url = jira_url
        self.auth_token = auth_token
        self.project_key = project_key
    
    def post_create(self, task: Dict[str, Any]) -> None:
        """Create corresponding JIRA issue."""
        if task.get('sync_jira', False):
            jira_issue = self._create_jira_issue(task)
            if jira_issue:
                # Store JIRA issue key in task
                self._update_task_jira_key(task['id'], jira_issue['key'])
    
    def post_complete(self, task: Dict[str, Any]) -> None:
        """Close JIRA issue when task completed."""
        jira_key = task.get('jira_key')
        if jira_key:
            self._close_jira_issue(jira_key)
    
    def _create_jira_issue(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Create JIRA issue via REST API."""
        headers = {
            'Authorization': f'Bearer {self.auth_token}',
            'Content-Type': 'application/json'
        }
        
        issue_data = {
            'fields': {
                'project': {'key': self.project_key},
                'summary': task['title'],
                'description': task.get('description', ''),
                'issuetype': {'name': 'Task'},
                'priority': {'name': self._map_priority(task.get('priority', 'medium'))}
            }
        }
        
        try:
            response = requests.post(
                f'{self.jira_url}/rest/api/2/issue',
                headers=headers,
                json=issue_data,
                timeout=10
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException:
            return None
    
    def _map_priority(self, priority: str) -> str:
        """Map Task Orchestrator priority to JIRA priority."""
        mapping = {
            'low': 'Low',
            'medium': 'Medium',
            'high': 'High',
            'critical': 'Highest'
        }
        return mapping.get(priority, 'Medium')
```

### Plugin Management

```python
class PluginManager:
    """Manages Task Orchestrator plugins."""
    
    def __init__(self):
        self.plugins = {}
        self.loaded_plugins = []
    
    def register_plugin(self, plugin: TaskOrchestratorPlugin, config: Dict[str, Any] = None) -> None:
        """Register and initialize a plugin."""
        plugin_name = plugin.get_name()
        
        if plugin_name in self.plugins:
            raise ValueError(f"Plugin {plugin_name} already registered")
        
        # Initialize plugin
        if config:
            plugin.initialize(config)
        
        self.plugins[plugin_name] = plugin
        self.loaded_plugins.append(plugin)
    
    def get_all_hooks(self) -> List[Any]:
        """Get all hooks from all plugins."""
        hooks = []
        for plugin in self.loaded_plugins:
            hooks.extend(plugin.get_hooks())
        return hooks
    
    def get_all_validators(self) -> List[Any]:
        """Get all validators from all plugins."""
        validators = []
        for plugin in self.loaded_plugins:
            validators.extend(plugin.get_validators())
        return validators
    
    def shutdown_all(self) -> None:
        """Shutdown all plugins."""
        for plugin in self.loaded_plugins:
            plugin.shutdown()

# Usage
plugin_manager = PluginManager()

# Register JIRA plugin
jira_config = {
    'jira_url': 'https://yourcompany.atlassian.net',
    'auth_token': 'your-api-token',
    'project_key': 'PROJ'
}
plugin_manager.register_plugin(JiraIntegrationPlugin(), jira_config)

# Initialize TaskManager with plugins
tm = TaskManager()
tm.set_plugin_manager(plugin_manager)
```

## Development Setup

### Plugin Development Environment

1. **Create plugin directory structure:**
```bash
my_plugin/
├── __init__.py
├── plugin.py
├── validators/
│   ├── __init__.py
│   └── custom_validator.py
├── hooks/
│   ├── __init__.py
│   └── custom_hook.py
├── tests/
│   ├── __init__.py
│   └── test_plugin.py
├── requirements.txt
└── README.md
```

2. **Plugin template:**
```python
# my_plugin/plugin.py
from task_orchestrator.plugins import TaskOrchestratorPlugin

class MyCustomPlugin(TaskOrchestratorPlugin):
    def get_name(self) -> str:
        return "my_custom_plugin"
    
    def get_version(self) -> str:
        return "1.0.0"
    
    def initialize(self, config: Dict[str, Any]) -> None:
        # Initialize your plugin
        pass
    
    def get_validators(self) -> List[Any]:
        from .validators.custom_validator import MyValidator
        return [MyValidator()]
    
    def get_hooks(self) -> List[Any]:
        from .hooks.custom_hook import MyHook
        return [MyHook()]
```

3. **Testing framework:**
```python
# my_plugin/tests/test_plugin.py
import unittest
from unittest.mock import Mock, patch
from my_plugin.plugin import MyCustomPlugin

class TestMyCustomPlugin(unittest.TestCase):
    def setUp(self):
        self.plugin = MyCustomPlugin()
    
    def test_plugin_name(self):
        self.assertEqual(self.plugin.get_name(), "my_custom_plugin")
    
    def test_validators(self):
        validators = self.plugin.get_validators()
        self.assertGreater(len(validators), 0)
    
    def test_hooks(self):
        hooks = self.plugin.get_hooks()
        self.assertGreater(len(hooks), 0)

if __name__ == '__main__':
    unittest.main()
```

## Testing Extensions

### Unit Testing Custom Validators

```python
import unittest
from your_extension import HttpStatusValidator

class TestHttpStatusValidator(unittest.TestCase):
    def setUp(self):
        self.validator = HttpStatusValidator()
    
    def test_valid_http_status(self):
        criterion = {
            "criterion": "API is healthy",
            "measurable": "http_status:https://httpbin.org/status/200:200"
        }
        
        result = self.validator.validate(criterion)
        self.assertTrue(result)
    
    def test_invalid_http_status(self):
        criterion = {
            "criterion": "API is broken",
            "measurable": "http_status:https://httpbin.org/status/500:200"
        }
        
        result = self.validator.validate(criterion)
        self.assertFalse(result)
    
    def test_invalid_format(self):
        criterion = {
            "criterion": "Invalid format",
            "measurable": "invalid_format"
        }
        
        result = self.validator.validate(criterion)
        self.assertFalse(result)
```

### Integration Testing

```python
import unittest
from task_orchestrator import TaskManager
from your_extension import MyCustomPlugin

class TestIntegration(unittest.TestCase):
    def setUp(self):
        self.tm = TaskManager()
        
        # Register plugin
        plugin = MyCustomPlugin()
        self.tm.register_plugin(plugin)
    
    def test_custom_validator_integration(self):
        # Create task with custom validation
        task_id = self.tm.add(
            "Test custom validation",
            criteria='[{"criterion":"Custom check","measurable":"custom:test_value"}]'
        )
        
        # Complete with validation
        result = self.tm.complete(task_id, validate=True)
        self.assertTrue(result)
    
    def test_hook_execution(self):
        # Create task (should trigger hooks)
        task_id = self.tm.add("Test hook execution")
        
        # Verify hook was called
        # (This would require mock verification)
        pass
```

### Performance Testing Extensions

```python
import time
import unittest
from task_orchestrator import TaskManager

class TestPerformance(unittest.TestCase):
    def test_validator_performance(self):
        """Ensure validators don't add significant overhead."""
        tm = TaskManager()
        
        # Time without validation
        start = time.time()
        for i in range(100):
            task_id = tm.add(f"Task {i}")
            tm.complete(task_id)
        no_validation_time = time.time() - start
        
        # Time with validation
        start = time.time()
        for i in range(100):
            task_id = tm.add(
                f"Task {i}",
                criteria='[{"criterion":"Always passes","measurable":"true"}]'
            )
            tm.complete(task_id, validate=True)
        validation_time = time.time() - start
        
        # Validation should add <50% overhead
        overhead = (validation_time - no_validation_time) / no_validation_time
        self.assertLess(overhead, 0.5)
```

---

## Best Practices

1. **Keep validators simple and fast**
2. **Handle errors gracefully**
3. **Provide clear error messages**
4. **Use dependency injection for testability**
5. **Document extension APIs thoroughly**
6. **Version your extensions**
7. **Provide migration paths for breaking changes**

## See Also

- [API Reference](../api/core-loop-api-reference.md)
- [Architecture Overview](../architecture/core-loop-architecture.md)
- [Testing Guide](../testing/testing-core-loop.md)
- [Integration Patterns](../integrations/integration-patterns.md)