# Integration Patterns for Core Loop

## Overview

This guide provides practical patterns for integrating Task Orchestrator Core Loop features with external systems, CI/CD pipelines, development tools, and monitoring platforms.

## Table of Contents

- [CI/CD Integration](#cicd-integration)
- [Claude Code Integration](#claude-code-integration)  
- [Git Hooks](#git-hooks)
- [External Systems](#external-systems)
- [Monitoring Integration](#monitoring-integration)
- [IDE Integration](#ide-integration)
- [Authentication & Security](#authentication--security)

## CI/CD Integration

### GitHub Actions

#### Basic Integration

```yaml
# .github/workflows/task-orchestrator.yml
name: Task Orchestrator Integration

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  TM_AGENT_ID: "github-actions"

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Task Orchestrator
      run: |
        chmod +x tm
        ./tm init
    
    - name: Create build task
      id: create_task
      run: |
        TASK_ID=$(./tm add "Build commit ${{ github.sha }}" \
          --criteria '[{"criterion":"Tests pass","measurable":"true"},
                      {"criterion":"Coverage > 80%","measurable":"coverage > 80"}]' \
          --deadline "$(date -d '+1 hour' -Iseconds)" \
          --estimated-hours 0.5 | grep -o '[a-f0-9]\{8\}')
        echo "task_id=$TASK_ID" >> $GITHUB_OUTPUT
    
    - name: Update progress - Dependencies
      run: |
        ./tm progress ${{ steps.create_task.outputs.task_id }} "Installing dependencies"
    
    - name: Install dependencies
      run: |
        npm install
    
    - name: Update progress - Testing
      run: |
        ./tm progress ${{ steps.create_task.outputs.task_id }} "Running tests"
    
    - name: Run tests
      id: test
      run: |
        npm test -- --coverage
        COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
        echo "coverage=$COVERAGE" >> $GITHUB_OUTPUT
    
    - name: Complete task with validation
      run: |
        ./tm complete ${{ steps.create_task.outputs.task_id }} \
          --validate \
          --actual-hours 0.3 \
          --summary "Build successful. Coverage: ${{ steps.test.outputs.coverage }}%. All tests passing."
        
        # Add feedback based on coverage
        if (( $(echo "${{ steps.test.outputs.coverage }} >= 90" | bc -l) )); then
          QUALITY=5
        elif (( $(echo "${{ steps.test.outputs.coverage }} >= 80" | bc -l) )); then
          QUALITY=4
        else
          QUALITY=3
        fi
        
        ./tm feedback ${{ steps.create_task.outputs.task_id }} \
          --quality $QUALITY \
          --timeliness 5 \
          --note "Automated build pipeline completion"
    
    - name: Export metrics
      if: always()
      run: |
        ./tm metrics --feedback > build-metrics.json
        cat build-metrics.json
    
    - name: Upload task data
      if: always()
      uses: actions/upload-artifact@v3
      with:
        name: task-orchestrator-data
        path: |
          .task-orchestrator/
          build-metrics.json
```

#### Advanced Multi-Stage Pipeline

```yaml
# .github/workflows/advanced-pipeline.yml
name: Advanced Task Orchestrator Pipeline

on:
  push:
    branches: [ main ]

jobs:
  plan:
    runs-on: ubuntu-latest
    outputs:
      epic_id: ${{ steps.epic.outputs.task_id }}
      frontend_id: ${{ steps.frontend.outputs.task_id }}
      backend_id: ${{ steps.backend.outputs.task_id }}
      deploy_id: ${{ steps.deploy.outputs.task_id }}
    
    steps:
    - uses: actions/checkout@v3
    - name: Setup Task Orchestrator
      run: |
        chmod +x tm
        ./tm init
    
    - name: Create epic
      id: epic
      run: |
        EPIC_ID=$(./tm add "Release Pipeline ${{ github.run_number }}" \
          --criteria '[{"criterion":"All tests pass","measurable":"true"},
                      {"criterion":"Security scan clean","measurable":"security_issues == 0"},
                      {"criterion":"Performance acceptable","measurable":"response_time < 500"}]' \
          --priority critical \
          --estimated-hours 2 | grep -o '[a-f0-9]\{8\}')
        echo "task_id=$EPIC_ID" >> $GITHUB_OUTPUT
    
    - name: Create frontend task
      id: frontend
      run: |
        TASK_ID=$(./tm add "Frontend build and test" \
          --depends-on ${{ steps.epic.outputs.task_id }} \
          --criteria '[{"criterion":"Build succeeds","measurable":"true"}]' \
          --estimated-hours 0.5 | grep -o '[a-f0-9]\{8\}')
        echo "task_id=$TASK_ID" >> $GITHUB_OUTPUT
    
    - name: Create backend task  
      id: backend
      run: |
        TASK_ID=$(./tm add "Backend build and test" \
          --depends-on ${{ steps.epic.outputs.task_id }} \
          --criteria '[{"criterion":"API tests pass","measurable":"true"}]' \
          --estimated-hours 0.7 | grep -o '[a-f0-9]\{8\}')
        echo "task_id=$TASK_ID" >> $GITHUB_OUTPUT
    
    - name: Create deploy task
      id: deploy
      run: |
        TASK_ID=$(./tm add "Deploy to staging" \
          --depends-on ${{ steps.frontend.outputs.task_id }} \
          --depends-on ${{ steps.backend.outputs.task_id }} \
          --criteria '[{"criterion":"Health check passes","measurable":"true"}]' \
          --estimated-hours 0.3 | grep -o '[a-f0-9]\{8\}')
        echo "task_id=$TASK_ID" >> $GITHUB_OUTPUT

  frontend:
    needs: plan
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Setup
      run: |
        chmod +x tm
        ./tm init
    - name: Frontend build
      run: |
        ./tm progress ${{ needs.plan.outputs.frontend_id }} "Building frontend"
        npm run build:frontend
        ./tm complete ${{ needs.plan.outputs.frontend_id }} --validate

  backend:
    needs: plan
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Setup
      run: |
        chmod +x tm
        ./tm init
    - name: Backend build
      run: |
        ./tm progress ${{ needs.plan.outputs.backend_id }} "Building backend"
        npm run build:backend
        npm run test:api
        ./tm complete ${{ needs.plan.outputs.backend_id }} --validate

  deploy:
    needs: [plan, frontend, backend]
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Setup
      run: |
        chmod +x tm
        ./tm init
    - name: Deploy
      run: |
        ./tm progress ${{ needs.plan.outputs.deploy_id }} "Deploying to staging"
        # Deploy logic here
        ./tm complete ${{ needs.plan.outputs.deploy_id }} --validate
        
        # Complete epic
        ./tm complete ${{ needs.plan.outputs.epic_id }} \
          --validate \
          --summary "Full pipeline completed successfully"
```

### Jenkins Integration

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    environment {
        TM_AGENT_ID = "jenkins-${BUILD_NUMBER}"
    }
    
    stages {
        stage('Setup') {
            steps {
                script {
                    sh './tm init'
                    env.TASK_ID = sh(
                        script: """./tm add "Jenkins Build ${BUILD_NUMBER}" \
                                 --criteria '[{"criterion":"Build succeeds","measurable":"true"}]' \
                                 --estimated-hours 1 | grep -o '[a-f0-9]\\{8\\}'""",
                        returnStdout: true
                    ).trim()
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    sh """./tm progress ${env.TASK_ID} "Building application" """
                    sh 'npm run build'
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    sh """./tm progress ${env.TASK_ID} "Running tests" """
                    sh 'npm test'
                }
            }
        }
        
        stage('Complete') {
            steps {
                script {
                    sh """./tm complete ${env.TASK_ID} \
                         --validate \
                         --actual-hours 0.8 \
                         --summary "Jenkins build ${BUILD_NUMBER} completed successfully" """
                    
                    sh """./tm feedback ${env.TASK_ID} \
                         --quality 4 \
                         --timeliness 4 \
                         --note "Automated Jenkins build" """
                }
            }
        }
    }
    
    post {
        always {
            script {
                sh './tm metrics --feedback > jenkins-metrics.json'
                archiveArtifacts artifacts: 'jenkins-metrics.json', allowEmptyArchive: true
            }
        }
        
        failure {
            script {
                sh """./tm progress ${env.TASK_ID} "Build failed - see Jenkins logs" """
            }
        }
    }
}
```

## Claude Code Integration

### Enhanced Workflow

```bash
# .clauderc - Claude Code configuration
{
  "whitelisted_commands": [
    "./tm *",
    "tm *"
  ],
  "task_orchestrator": {
    "auto_progress": true,
    "context_sharing": true,
    "metrics_integration": true
  }
}
```

### Claude Code Integration Script

```python
#!/usr/bin/env python3
# claude_tm_integration.py
"""
Enhanced Claude Code integration for Task Orchestrator
"""

import os
import re
import json
import subprocess
from pathlib import Path
from typing import Dict, List, Optional

class ClaudeTaskIntegration:
    def __init__(self):
        self.tm_path = self._find_tm_executable()
        self.agent_id = "claude-code"
        
    def _find_tm_executable(self) -> str:
        """Find tm executable in current directory or PATH."""
        if Path("./tm").exists():
            return "./tm"
        elif Path("tm").exists():
            return "tm"
        else:
            # Check PATH
            try:
                result = subprocess.run(["which", "tm"], capture_output=True, text=True)
                if result.returncode == 0:
                    return result.stdout.strip()
            except FileNotFoundError:
                pass
        raise FileNotFoundError("tm executable not found")
    
    def auto_create_task_from_comment(self, file_path: str, comment: str) -> Optional[str]:
        """
        Auto-create task from TODO comments in code.
        
        Supports formats:
        # TODO: Fix authentication bug [priority:high] [estimate:2h]
        # FIXME: Optimize database query [criteria:performance<100ms]
        """
        todo_pattern = r'(TODO|FIXME|HACK):\s*(.+?)(?:\[(.+?)\])*'
        match = re.search(todo_pattern, comment)
        
        if not match:
            return None
        
        task_type, description, options = match.groups()
        
        # Parse options
        priority = "medium"
        estimated_hours = None
        criteria = None
        
        if options:
            for option in re.findall(r'([^:]+):([^,\]]+)', options):
                key, value = option
                if key.strip() == "priority":
                    priority = value.strip()
                elif key.strip() == "estimate":
                    # Parse "2h", "30m", "1.5h"
                    if 'h' in value:
                        estimated_hours = float(value.replace('h', ''))
                    elif 'm' in value:
                        estimated_hours = float(value.replace('m', '')) / 60
                elif key.strip() == "criteria":
                    criteria = f'[{{"criterion":"Performance acceptable","measurable":"{value.strip()}"}}]'
        
        # Create task
        cmd = [
            self.tm_path, "add", f"{task_type}: {description}",
            "--priority", priority,
            "--file", f"{file_path}:1"  # Would need line number detection
        ]
        
        if estimated_hours:
            cmd.extend(["--estimated-hours", str(estimated_hours)])
        
        if criteria:
            cmd.extend(["--criteria", criteria])
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                # Extract task ID from output
                task_id_match = re.search(r'([a-f0-9]{8})', result.stdout)
                return task_id_match.group(1) if task_id_match else None
        except subprocess.SubprocessError:
            pass
        
        return None
    
    def update_progress_from_git(self, task_id: str) -> bool:
        """Update task progress based on git commit messages."""
        try:
            # Get latest commit message
            result = subprocess.run(
                ["git", "log", "-1", "--pretty=%B"],
                capture_output=True, text=True
            )
            
            if result.returncode == 0:
                commit_msg = result.stdout.strip()
                
                # Check if commit mentions the task
                if task_id in commit_msg or f"#{task_id}" in commit_msg:
                    progress_msg = f"Git commit: {commit_msg.split(chr(10))[0]}"  # First line
                    
                    subprocess.run([
                        self.tm_path, "progress", task_id, progress_msg
                    ], capture_output=True)
                    
                    return True
        except subprocess.SubprocessError:
            pass
        
        return False
    
    def get_context_for_claude(self) -> Dict:
        """Get task context for Claude Code sessions."""
        try:
            # Get active tasks
            result = subprocess.run([
                self.tm_path, "list", "--status", "in_progress"
            ], capture_output=True, text=True)
            
            context = {
                "active_tasks": [],
                "recent_completions": [],
                "current_metrics": {}
            }
            
            if result.returncode == 0:
                # Parse active tasks
                for line in result.stdout.split('\n'):
                    if line.strip():
                        context["active_tasks"].append(line.strip())
            
            # Get recent metrics
            metrics_result = subprocess.run([
                self.tm_path, "metrics", "--feedback"
            ], capture_output=True, text=True)
            
            if metrics_result.returncode == 0:
                try:
                    context["current_metrics"] = json.loads(metrics_result.stdout)
                except json.JSONDecodeError:
                    context["current_metrics"] = {"raw": metrics_result.stdout}
            
            return context
            
        except subprocess.SubprocessError:
            return {"error": "Could not fetch task context"}

# Usage in Claude Code session
if __name__ == "__main__":
    integration = ClaudeTaskIntegration()
    
    # Example: Auto-create task from comment
    task_id = integration.auto_create_task_from_comment(
        "src/auth.py",
        "# TODO: Fix race condition in session cleanup [priority:high] [estimate:3h]"
    )
    
    if task_id:
        print(f"Created task: {task_id}")
    
    # Get context for Claude
    context = integration.get_context_for_claude()
    print(json.dumps(context, indent=2))
```

## Git Hooks

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Task Orchestrator pre-commit integration

# Check for TODO comments and suggest creating tasks
echo "Checking for TODO comments..."

NEW_TODOS=$(git diff --cached --diff-filter=A -U0 | grep -E '^\+.*TODO|^\+.*FIXME|^\+.*HACK' || true)

if [ -n "$NEW_TODOS" ]; then
    echo "Found new TODO comments:"
    echo "$NEW_TODOS"
    echo ""
    echo "Consider creating tasks for these TODOs:"
    echo "$NEW_TODOS" | while read -r line; do
        if [[ $line =~ ^\+.*TODO:(.+)$ ]]; then
            TODO_TEXT="${BASH_REMATCH[1]}"
            echo "  ./tm add \"TODO:$TODO_TEXT\" --priority medium"
        fi
    done
    echo ""
fi

# Update progress for tasks mentioned in commit
COMMIT_MSG_FILE=".git/COMMIT_EDITMSG"
if [ -f "$COMMIT_MSG_FILE" ]; then
    COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")
    
    # Look for task IDs in commit message (format: #task_id or task_id)
    TASK_IDS=$(echo "$COMMIT_MSG" | grep -oE '\b[a-f0-9]{8}\b|\#[a-f0-9]{8}' | sed 's/^#//')
    
    for TASK_ID in $TASK_IDS; do
        if ./tm show "$TASK_ID" >/dev/null 2>&1; then
            ./tm progress "$TASK_ID" "Pre-commit: $(echo "$COMMIT_MSG" | head -1)"
        fi
    done
fi

# Run standard pre-commit checks
exit 0
```

### Post-commit Hook

```bash
#!/bin/bash
# .git/hooks/post-commit

# Get the commit message
COMMIT_MSG=$(git log -1 --pretty=%B)
COMMIT_HASH=$(git log -1 --pretty=%H | cut -c1-8)

# Look for task references
TASK_IDS=$(echo "$COMMIT_MSG" | grep -oE '\b[a-f0-9]{8}\b|\#[a-f0-9]{8}' | sed 's/^#//')

for TASK_ID in $TASK_IDS; do
    if ./tm show "$TASK_ID" >/dev/null 2>&1; then
        # Update progress with commit info
        ./tm progress "$TASK_ID" "Commit $COMMIT_HASH: $(echo "$COMMIT_MSG" | head -1)"
        
        # If commit message contains "fix", "complete", or "done", suggest completion
        if echo "$COMMIT_MSG" | grep -iE '\b(fix|complete|done|finished)\b' >/dev/null; then
            echo "Commit suggests task completion. Consider:"
            echo "  ./tm complete $TASK_ID --summary \"$(echo "$COMMIT_MSG" | head -1)\""
        fi
    fi
done
```

## External Systems

### Slack Integration

```python
import requests
import json
from typing import Dict, Any

class SlackTaskIntegration:
    def __init__(self, webhook_url: str, channel: str = None):
        self.webhook_url = webhook_url
        self.channel = channel
    
    def send_task_notification(self, task: Dict[str, Any], event: str) -> bool:
        """Send task notification to Slack."""
        
        color_map = {
            'created': '#36a64f',
            'completed': '#2eb886', 
            'blocked': '#ff9900',
            'high_priority': '#ff0000'
        }
        
        emoji_map = {
            'created': '🆕',
            'completed': '✅',
            'blocked': '🚫',
            'high_priority': '🚨'
        }
        
        title = f"{emoji_map.get(event, '📋')} Task {event.title()}"
        
        fields = [
            {
                "title": "Title",
                "value": task['title'],
                "short": False
            },
            {
                "title": "Priority",
                "value": task.get('priority', 'medium').title(),
                "short": True
            },
            {
                "title": "Assignee", 
                "value": task.get('assignee', 'Unassigned'),
                "short": True
            }
        ]
        
        if task.get('deadline'):
            fields.append({
                "title": "Deadline",
                "value": task['deadline'],
                "short": True
            })
        
        if event == 'completed' and task.get('feedback_quality'):
            fields.append({
                "title": "Quality Score",
                "value": f"{task['feedback_quality']}/5",
                "short": True
            })
        
        payload = {
            "text": title,
            "attachments": [{
                "color": color_map.get(event, '#36a64f'),
                "title": f"Task {task['id']}",
                "fields": fields,
                "footer": "Task Orchestrator",
                "ts": int(time.time())
            }]
        }
        
        if self.channel:
            payload["channel"] = self.channel
        
        try:
            response = requests.post(self.webhook_url, json=payload, timeout=5)
            return response.status_code == 200
        except requests.RequestException:
            return False

# Usage
slack = SlackTaskIntegration("https://hooks.slack.com/services/...")

# Hook into TaskManager events
def on_task_created(task):
    if task.get('priority') in ['high', 'critical']:
        slack.send_task_notification(task, 'high_priority')
    else:
        slack.send_task_notification(task, 'created')

def on_task_completed(task):
    slack.send_task_notification(task, 'completed')
```

### JIRA Synchronization

```python
import requests
from typing import Dict, Optional

class JiraTaskSync:
    def __init__(self, jira_url: str, username: str, api_token: str, project_key: str):
        self.jira_url = jira_url.rstrip('/')
        self.auth = (username, api_token)
        self.project_key = project_key
    
    def sync_task_to_jira(self, task: Dict) -> Optional[str]:
        """Create or update JIRA issue for task."""
        
        # Check if task already has JIRA issue
        jira_key = task.get('jira_key')
        
        if jira_key:
            return self._update_jira_issue(jira_key, task)
        else:
            return self._create_jira_issue(task)
    
    def _create_jira_issue(self, task: Dict) -> Optional[str]:
        """Create new JIRA issue."""
        
        issue_data = {
            "fields": {
                "project": {"key": self.project_key},
                "summary": task['title'],
                "description": self._format_description(task),
                "issuetype": {"name": "Task"},
                "priority": {"name": self._map_priority(task.get('priority', 'medium'))},
                "labels": ["task-orchestrator", f"tm-{task['id']}"]
            }
        }
        
        if task.get('assignee'):
            # Map assignee to JIRA user
            jira_user = self._map_assignee(task['assignee'])
            if jira_user:
                issue_data["fields"]["assignee"] = {"name": jira_user}
        
        try:
            response = requests.post(
                f"{self.jira_url}/rest/api/2/issue",
                json=issue_data,
                auth=self.auth,
                headers={"Content-Type": "application/json"},
                timeout=10
            )
            
            if response.status_code == 201:
                issue = response.json()
                return issue['key']
                
        except requests.RequestException:
            pass
        
        return None
    
    def _update_jira_issue(self, jira_key: str, task: Dict) -> str:
        """Update existing JIRA issue."""
        
        update_data = {
            "fields": {
                "summary": task['title'],
                "description": self._format_description(task),
                "priority": {"name": self._map_priority(task.get('priority', 'medium'))}
            }
        }
        
        # Update status based on task status
        if task['status'] == 'completed':
            self._transition_issue(jira_key, "Done")
        elif task['status'] == 'in_progress':
            self._transition_issue(jira_key, "In Progress")
        
        try:
            requests.put(
                f"{self.jira_url}/rest/api/2/issue/{jira_key}",
                json=update_data,
                auth=self.auth,
                headers={"Content-Type": "application/json"},
                timeout=10
            )
        except requests.RequestException:
            pass
        
        return jira_key
    
    def _format_description(self, task: Dict) -> str:
        """Format task description for JIRA."""
        desc = task.get('description', '')
        
        # Add Task Orchestrator metadata
        desc += f"\n\n*Task Orchestrator ID:* {task['id']}"
        
        if task.get('success_criteria'):
            desc += f"\n*Success Criteria:* {task['success_criteria']}"
        
        if task.get('estimated_hours'):
            desc += f"\n*Estimated Hours:* {task['estimated_hours']}"
        
        return desc
    
    def _map_priority(self, tm_priority: str) -> str:
        """Map Task Orchestrator priority to JIRA priority."""
        mapping = {
            'low': 'Low',
            'medium': 'Medium', 
            'high': 'High',
            'critical': 'Highest'
        }
        return mapping.get(tm_priority, 'Medium')
    
    def _map_assignee(self, tm_assignee: str) -> Optional[str]:
        """Map Task Orchestrator assignee to JIRA username."""
        # This would need to be customized based on your user mapping
        assignee_mapping = {
            'alice': 'alice.smith',
            'bob': 'bob.jones'
        }
        return assignee_mapping.get(tm_assignee)
```

## Monitoring Integration

### Prometheus Metrics Export

```python
# prometheus_exporter.py
import time
from prometheus_client import start_http_server, Gauge, Counter, Histogram
from task_orchestrator import TaskManager

class TaskOrchestratorMetrics:
    def __init__(self):
        # Metrics definitions
        self.tasks_total = Counter('tm_tasks_total', 'Total tasks created', ['priority', 'assignee'])
        self.tasks_completed = Counter('tm_tasks_completed_total', 'Total completed tasks', ['assignee'])
        self.task_duration = Histogram('tm_task_duration_hours', 'Task completion time in hours')
        self.quality_score = Gauge('tm_quality_score_avg', 'Average quality score', ['assignee'])
        self.pending_tasks = Gauge('tm_pending_tasks', 'Number of pending tasks')
        self.blocked_tasks = Gauge('tm_blocked_tasks', 'Number of blocked tasks')
        
        self.tm = TaskManager()
    
    def collect_metrics(self):
        """Collect current metrics from Task Orchestrator."""
        
        # Get all tasks
        tasks = self.tm._get_all_tasks()  # Internal method
        
        # Reset gauges
        self.pending_tasks.set(0)
        self.blocked_tasks.set(0)
        
        # Count by status
        status_counts = {'pending': 0, 'blocked': 0}
        
        for task in tasks:
            status = task['status']
            if status in status_counts:
                status_counts[status] += 1
        
        self.pending_tasks.set(status_counts['pending'])
        self.blocked_tasks.set(status_counts['blocked'])
        
        # Quality metrics by assignee
        assignee_quality = {}
        assignee_counts = {}
        
        for task in tasks:
            assignee = task.get('assignee', 'unassigned')
            quality = task.get('feedback_quality')
            
            if quality:
                if assignee not in assignee_quality:
                    assignee_quality[assignee] = []
                assignee_quality[assignee].append(quality)
        
        # Set quality gauges
        for assignee, qualities in assignee_quality.items():
            avg_quality = sum(qualities) / len(qualities)
            self.quality_score.labels(assignee=assignee).set(avg_quality)
    
    def run_server(self, port=8000):
        """Start Prometheus metrics server."""
        start_http_server(port)
        print(f"Prometheus metrics server started on port {port}")
        
        while True:
            self.collect_metrics()
            time.sleep(30)  # Update every 30 seconds

if __name__ == "__main__":
    metrics = TaskOrchestratorMetrics()
    metrics.run_server()
```

### Grafana Dashboard Configuration

```json
{
  "dashboard": {
    "title": "Task Orchestrator Metrics",
    "panels": [
      {
        "title": "Task Status Overview",
        "type": "stat",
        "targets": [
          {
            "expr": "tm_pending_tasks",
            "legendFormat": "Pending"
          },
          {
            "expr": "tm_blocked_tasks", 
            "legendFormat": "Blocked"
          }
        ]
      },
      {
        "title": "Quality Scores by Assignee",
        "type": "graph",
        "targets": [
          {
            "expr": "tm_quality_score_avg",
            "legendFormat": "{{assignee}}"
          }
        ]
      },
      {
        "title": "Task Completion Rate",
        "type": "graph", 
        "targets": [
          {
            "expr": "rate(tm_tasks_completed_total[5m])",
            "legendFormat": "Completions/min"
          }
        ]
      }
    ]
  }
}
```

---

## Best Practices

1. **Use environment variables for configuration**
2. **Implement proper error handling**
3. **Add authentication where needed**
4. **Monitor integration health**
5. **Provide clear documentation**
6. **Test integrations in staging**
7. **Handle rate limits gracefully**
8. **Use webhooks for real-time updates**

## See Also

- [Extension Guide](../extending/extending-core-loop.md)
- [API Reference](../api/core-loop-api-reference.md)
- [Testing Guide](../testing/testing-core-loop.md)